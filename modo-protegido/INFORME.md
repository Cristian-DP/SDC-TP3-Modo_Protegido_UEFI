# Modo protegido

## Introducción

Los procesadores x86 mantienen compatibilidad con sus antecesores y para agregar nuevas funcionalidades deben ir “evolucionando” en el tiempo durante el proceso de arranque. Todos los CPUs x86 comienzan en modo real en el momento de carga (boot time) para asegurar compatibilidad hacia atrás,  en cuanto se los energiza se comportan  de manera muy primitiva, luego mediante comandos se los hace evolucionar hasta poder obtener la máxima cantidad de prestaciones posibles.El modo protegido es un modo operacional de los CPUs compatibles x86 de la serie 80286 y posteriores. Este modo es el primer salto evolutivo de los x86. El modo protegido tiene un número de nuevas características diseñadas para mejorar la multitarea y la estabilidad del sistema, tales como la protección de memoria, y soporte de hardware para memoria virtual como también la conmutación de tareas.

## Enunciado

[Link](https://docs.google.com/document/d/1Y-MSIlVy9gCUEqxakHh95rBnM1RaSJZYPCq-UVWYarE/edit?hl=es&tab=t.0#heading=h.cqdj6qinubi8)

En este TP ejecutaremos un trozo de código que configura nuestro procesador para llevarlo desde el modo real al modo protegido.

Antes de la clase:
* Revisar el teórico
* Clonen este repositorio e inicializan los submódulos (ver README).

https://gitlab.com/sistemas-de-computacion-2021/protected-mode-sdc

Se adjunta el manual del desarrollador para procesadores x86 de Intel.

Y un repositorio de código muy interesante para el práctico que ya está incluido en el repositorio clonado.

https://github.com/cirosantilli/x86-bare-metal-examples

Para este trabajo deberán realizar un informe que responda a las consignas que se encuentran en la presentación. Mostrar la ejecución del ejemplo en una máquina virtual explicando lo que sucede.

¿Te animas a explorar UEFI…?

si te animas podes empezar por aquí 

* https://github.com/utshina/uefi-simple/tree/master 
* https://wiki.osdev.org/UEFI_App_Bare_Bones 


## Cuestionario

- Crear un código assembler que pueda pasar a modo protegido (sin macros).

[ir a code](./code/sin_macros.S)

- ¿Cómo sería un programa que tenga dos descriptores de memoria diferentes, uno para cada segmento (código y datos) en espacios de memoria diferenciados? 

Para lograr que los segmentos de código y datos estén en espacios de memoria diferenciados, debemos modificar la Base de los descriptores en la GDT.

En el código anterior, ambos tenían Base = 0x00000000 (técnica conocida como Flat Memory Model). En el archivo sin_macros_2.S se puede visualizar el cambio.

```
gdt_data:                       # Selector 0x10
    .word 0xffff, 0x0000, 0x9201, 0x00cf # El '01' en el byte 5 pone la base en 0x10000
```

- Cambiar los bits de acceso del segmento de datos para que sea de solo lectura,  intentar escribir, ¿Que sucede? ¿Que debería suceder a continuación? (revisar el teórico) Verificarlo con gdb. 

El segmento de datos (gdt_data) utiliza el valor de acceso 0x92 (que es 10010010 en binario).

* Bit 1 (W): Es el bit de "Writable". Al estar en 1, permite escritura.
* Bit 0 (A): Bit de "Accessed".

Para que sea de solo lectura, debemos cambiar ese 0x92 por 0x90 (binario 10010000).

```
gdt_data:                       # Selector 0x10
    .word 0xffff, 0x0000, 0x9001, 0x00cf  # Cambiado 92 por 90 (Solo Lectura)
```

* **¿Qué sucede al intentar escribir?** En la sección .code32, se realiza la siguiente operación: mov %al, (%edi) .
Al ejecutar esta instrucción con el segmento de datos en solo lectura: 
La Unidad de Gestión de Memoria (MMU) del procesador verifica el descriptor asociado al selector cargado en %ds (o el segmento usado para escribir).

Al detectar que el bit de escritura es 0 y la instrucción intenta una escritura, el hardware detiene la ejecución inmediatamente antes de que la memoria se vea afectada.

* **¿Qué debería suceder a continuación? (Según el teórico)**

A nivel de arquitectura x86, sucede lo siguiente:

* Excepción de Protección General (#GP): El procesador genera una interrupción de tipo Fault (vector 13).
* Búsqueda en la IDT: El procesador intenta buscar en la Interrupt Descriptor Table (IDT) el manejador para la excepción 13.
* Triple Fault: Como en tu código actual no tienes una IDT configurada, el procesador falla al intentar manejar la excepción #GP, lo que genera una excepción de "Doble Falta" y, finalmente, al no poder manejar esa tampoco, ocurre un Triple Fault.
* Reinicio: En una PC real o QEMU, un Triple Fault provoca el reinicio instantáneo de la máquina (un reset por hardware).

* **Verificación con GDB**

Para ver y confirmar que el procesador se detiene por el error de protección, se uso:

* Lanza QEMU esperando a GDB: qemu-system-i386 -s -S -drive format=raw,file=kernel.img (donde -s: Abre un servidor GDB en el puerto 1234. 
-S: Congela la CPU al inicio.)

En otra terminal, se uso GDB:

```
gdb -ex "target remote localhost:1234" -ex "set architecture i8086"
```

Se colocó un breakpoint antes del desastre (Como sabemos que la BIOS carga el código en 0x7c00):

b *0x7c00
c (continuar)

* Observa el fallo:
* 
Avanzando con si (step instruction) llegamos a la instrucción mov %al, (%edi), verás que al intentar ejecutarla, QEMU se reinicia o, si inspeccionas los registros con info registers, verás que el registro EIP no avanza o salta a una dirección de error de la BIOS después del reset.

--

- En modo protegido, ¿Con qué valor se cargan los registros de segmento ? ¿Porque? 

En Modo Real, cargabas una dirección (ej: 0x07C0). En Modo Protegido, los registros (CS, DS, SS, etc.) se cargan con un Selector de Segmento.

¿Con qué valor?: Con un índice que apunta a la GDT. Por ejemplo, 0x08 (binario 00001000).

¿Por qué?: Porque el registro ya no es parte de la dirección física. Ahora funciona como un puntero a una tabla.

Los bits 3-15 son el Índice en la GDT.

El bit 2 es el indicador TI (GDT o LDT).

Los bits 0-1 son el RPL (Nivel de privilegio requerido, de 0 a 3).

Al cargar 0x08, le dices al procesador: "Usa las reglas (base, límite, permisos) definidas en la entrada 1 de la Tabla Global de Descriptores".


## Laboratorio: Compilar y correr una aplicación sin SO

* **Parte 1 – Clonar el repositorio Git y el submódulo**

[path al modulo clonado](../libs/protected-mode-sdc)

* **Paso 2: Trabajando con submódulos.**

![paso 2](../images/paso2.png)


![paso 2b](../images/paso2_b.png)

* **Parte 2: Compilar y ejecutar los ejemplos**

![paso 1](../images/parte2-paso1.png)

![paso 1 - protected](../images/parte2-paso1-protected.png)

* **Parte 3: Grabar la imagen y correrla en HW real (Se usa vBox)**

[Link al video deon se carga la vm con protected.img](https://drive.google.com/file/d/1YpCq4X7zdX75tpLB3bAOjuOSMB27jK2I/view?usp=sharing)

![paso 3 - disk](../images/parte3-paso1-disk.png)

1. ¿Se verá afectado el disco de mi PC real? 

No, siempre y cuando selecione la letra correcta. Al estar dentro de una máquina virtual (Mint), el sistema operativo solo ve los dispositivos que la VM le permite ver. El /dev/sdX que ve Mint es un disco virtual (un archivo .vdi o .vmdk en tu Windows).

Peligro: Si por algún error de configuración hubieras montado su disco físico de Windows dentro de la VM (passthrough), entonces sí. Pero por defecto, en VirtualBox/VMware, solo tocas el disco virtual.

2. ¿Se verá afectado el arranque de mi Windows?

No. Windows vive en el disco físico de tu computadora. Tu comando dd afectará únicamente al registro de arranque (MBR) y los sectores del disco virtual de la VM. Windows ni siquiera se enterará de que esto está pasando.

3. ¿Qué va a pasar con la VM cuando grabe y ejecute esto?
Aquí es donde la cosa se pone interesante:

Sobreescritura total: Si protected_mode.img es una imagen de un sector de arranque, borrarás el GRUB de Linux Mint.

Mint dejará de arrancar: La próxima vez que reinicies la VM, ya no entrarás a Linux Mint. En su lugar, se ejecutará el código de tu imagen.

Pérdida de datos: Si la imagen .img es grande, sobreescribirá la tabla de particiones y tus archivos de Mint. Si es solo de 512 bytes, solo destruirá el arranque de Mint, pero tus archivos seguirán ahí (aunque inaccesibles sin reparar el boot).