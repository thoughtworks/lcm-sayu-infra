# Infraestructura de sayu

## Cómo hacer login en AWS

El proyecto funciona con una cuenta de servicio de AWS. Terraform utilizará estas variable de ambiente AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, y sus valores deben hacer referencia al access key id y al secret access key de la cuenta de servicio.

## Consideraciones

- Se debe crear manualmente el bucket S3.
- Este proyecto funciona con S3 [backend](https://www.terraform.io/docs/backends/index.html) para guardar el estado de terraform
- Una vez creado el bucket de forma manual, la configuración de la conexión al bucket se realiza durante la ejecución del pipeline con estas variables de entorno: TF_BE_BUCKET, TF_BE_BUCKET_KEY
- El proyecto tiene dos workspace:
- tst: para pruebas de infraestructura e2e
- prod: configuración de entorno de producción

## Cómo desplegar la infraestructura

### En computador local

#### Inicializar el proyecto (solo una vez)

- `terraform init`: Inicializa el proyecto de terraform (descarga proveedores, establece conexión con el proyecto en la nube)

#### Con cada cambio en el código de Terraform

- `terraform validate`: valida la sintaxis del código

- `terraform plan`: busca las diferencias entre el estado y el código actual (verifique que el plan sea consistente con los cambios que quiera hacer)

- `terraform apply`: toma el plan y ejecuta los cambios en la nube

#### Destruir la Infraestructura

- `terraform destroy`: va al estado y destruye toda la infraestructura que se encuentra ahí.

### En el pipeline

- La herramienta de CI/CD utilizada es CircleCi que lee el archivo [.circleci/config.yml](/.circleci/config.yml) para generar un workflow (pipeline)
- CircleCi siempre ejecutará un init en cada job
- Cuando se ejecute el job `plan-apply` genere el plan de terraform, se detendrá el workflow y esperará por una aprobación manual (verifique que el plan sea consistente con los cambios que quiera hacer)
- Las variables de ambiente `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` deben estar disponibles y con sus valores correctos dentro de la configuración del proyecto en CircleCi ([ver más arriba](#cómo-hacer-login-en-aws))
- Por supuesto que se puede utilizar cualquier otra herramienta de CI/CD realizando los cambios necesarios

## Sobre las pruebas

Para probar la infraestructura se usa [terraform-compliance](https://terraform-compliance.com/).

### Sobre el cumplimiento de normas de Terraform

`terraform-compliance` es un marco de prueba ligero, centrado en la seguridad y el cumplimiento contra terraform para permitir la capacidad de prueba negativa para su infraestructura como código.

#### Instrucciones para correr las pruebas usando la librería

- **Instalar la librería:** asegúrese de instalar la librería `pip` o `docker`
- **Plan as Json:** asegúrese de guardar el plan de Terraform como un json

  1. `terraform plan -out terraform.out`
  2. `terraform show -json terraform.out > plan.json`

- **Ejecutar las pruebas:** Las pruebas se ejecutan en la carpeta de pruebas. Ej: tests

  1. `terraform-compliance -p plan.json -f tests`

- En el pipeline existe un job `run-tests` que configura el ambiente y ejecuta las pruebas `terraform-compliance`

## Sobre los entornos

Para diferentes entornos, usamos workspaces

### El pipeline usa dos entornos: tst y prod

### Si se necesita de un entorno adicional:

- **Crear nuevo workspace:**

  1. `terraform workspace new dev`

- **Seleccionar workspace creado:**

  2. `terraform workspace select dev`

- **Ejecutar plan:**

  3. `terraform plan -workspace=dev`

- **Ejecutar aplicación de plan:**

  4. `terraform apply -workspace=dev`

- Modificar pipeline de acuerdo a la existencia de un nuevo workspace (ej.: `if [[ $CIRCLE_BRANCH == "new_branch" ]]; then PROJECT_WORKSPACE=new_workspace`)
