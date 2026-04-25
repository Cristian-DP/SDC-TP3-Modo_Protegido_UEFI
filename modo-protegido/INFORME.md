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
- ¿Cómo sería un programa que tenga dos descriptores de memoria diferentes, uno para cada segmento (código y datos) en espacios de memoria diferenciados? 
- Cambiar los bits de acceso del segmento de datos para que sea de solo lectura,  intentar escribir, ¿Que sucede? ¿Que debería suceder a continuación? (revisar el teórico) Verificarlo con gdb. 
- En modo protegido, ¿Con qué valor se cargan los registros de segmento ? ¿Porque? 

## Laboratorio: Compilar y correr una aplicación sin SO

* **Parte 1 – Clonar el repositorio Git y el submódulo**

[path al modulo clonado](../libs/protected-mode-sdc)

* **Paso 2: Trabajando con submódulos.**

![paso 2](../images/paso2.png)


![paso 2b](../images/paso2_b.png)

* **Parte 2: Compilar y ejecutar los ejemplos**

![paso 1](../images/parte2-paso1.png)

![paso 1 - protected](../images/parte2-paso1-protected.png)

* **Parte 3: Grabar la imagen y correrla en HW real**

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