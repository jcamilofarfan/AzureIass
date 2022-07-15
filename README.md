# AzureIass

[Curso de Azure IaaS](https://platzi.com/cursos/azure-iaas/)

## Gestión de máquinas virtuales en la nube

Crea un conjunto de máquinas virtuales que por medio de un balanceador de cargas tengan la capacidad de presentar un sitio web a sus usuarios finales.


## Solucion
Se realzia creacion de un script automatizado que permite crear un grupo de recursos de Azure con el cual se tendra una alta disponibilidad de servicios web.


## Pasos previos

- Tener cuenta en el portal de [Azure](https://portal.azure.com)
- Instalar el CLI de azure, revisar [documentacion](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- Iniciar sesion desde el CLI
    ```bash
    az login
    ```
    Se abrira una ventana de navegador que nos permitira ingresar nuestras credenciales.

- Clonar repositorio de GitHub
    ```bash
    git clone https://github.com/jcamilofarfan/AzureIass.git
    cd AzureIass
    ```
- Correr el script de instalacion
    ```bash
    ./create-load-balancer.sh <resource-group> <numero-instancias>
    ```

### Nota
Si no permite ejecutar pr falta de permisos otorgar permisos de ejecucion al script.

    chmod +x create-load-balancer.sh

La consola mostrara mensajes de error si no se cumple alguna de las condiciones, e indicara cuando inicia la creacion de un recurso y cuando termina.

El Script creara la carpeta de logs para guardar la informacion de respuesta en formato JSON.

Y al finalizar mostrara la IP publica a la que se puede conectar para hacer la prueba de funcionamiento.
Lo recomendable es esperar unos minutos antes de realizar la prueba de funcionamiento mientras se crean y configuran las Máquinas Virtuales.