# gracias https://github.com/tavurth/godot-fft.git


# Proyecto VoIP en Godot

Este proyecto es una implementación en Godot Engine para la transmisión de voz a través de IP (VoIP) 
con compresión con pérdida utilizando técnicas de cuantización
La aplicación permite la transmisión eficiente de datos de audio a través de una red
optimizando el uso del ancho de banda. Además, incluye una clase para realizar transformadas
permitiendo la aplicación de técnicas avanzadas de procesamiento de señales.

## Descripción

El objetivo principal del proyecto es proporcionar una solución VoIP que aproveche técnicas de cuantización para comprimir los datos de audio antes de transmitirlos a través de la red.
La cuantización permite reducir el tamaño de los datos a costa de una pérdida de calidad mínima, ideal para aplicaciones donde el ancho de banda es limitado.

### Características Principales

- **Transmisión de Voz por IP**: Permite la comunicación de voz en tiempo real entre diferentes dispositivos a través de una dirección IP.
- **Compresión con Pérdida**: Utiliza técnicas de cuantización para comprimir los datos de audio
- **Procesamiento de Señales**: Incluye una clase para realizar transformadas
- **Integración con Godot**: Implementado completamente en Godot Engine

  
## Instalación

Sigue estos pasos para instalar y configurar el proyecto:

1. Clona el repositorio:
    ```bash
    git clone [https://github.com/.git](https://github.com/emagood/voip-2d.git]
    ```



2. Abre el proyecto en Godot Engine:
    - Ejecuta Godot y selecciona "Importar" para agregar el proyecto a la lista de proyectos.

## Uso

Para utilizar la herramienta de transmisión de voz:

1. Abre el archivo principal del proyecto en Godot.
2. Configura la dirección IP y el puerto en el script correspondiente.
3. Ejecuta la escena principal para iniciar la transmisión de voz.

## info 
en intervalos medios de omprenssion 
Tasa de bits original = 130 kbps
Tasa de bits comprimida = 30 kbps

Factor de compresion ≈ 4.33
