# 🛠️ Herramientas Utilizadas

* IDE: CursorAI
* Modelo: Claude Sonnet 4 + Superclaude

# 🚀 Desarrollo del Ejercicio

## 1. Configuración de entorno local de desarrollo

1. Configuré mis credenciales de AWS en local
2. Configuré el MCP de context7
3. Inicié con la ejecución de prompts

## 2. Ejecución: Prompts

### Prompt #1: Prompt para definir plan de trabajo

```markdown
/sc:analyze --persona-devops --think-hard --validate --c7 --seq
"                                                           
# Necesidad                                                 
Necesito implementar observabilidad en mi aplicación. Para esto requiero configurar, conectar y desplegar mi aplicacíón, conectada a mi cuenta de Datadog

# Contexto técnico                                          
1. La herramienta de IaC que usa mi aplicación, es Terraform
2. Ya he configurado en mi entorno local, las credenciales de mi cuenta y región de AWS con el comando: aws configure                                    
3. No tengo ninguna intención de hardcodear credenciales de AWS o de Datadog en mi base de código por seguridad                                          
4. Si bien, ya configuré mis credenciales de AWS en local, aún no se como configurar mi api-key de Datadog desde el CLI local para conectar mi proyecto a mi cuenta
5. Mi instancia EC2 está en la región us-west-2

# Formato de salida                                         
Dame un plan de trabajo detallado con subtareas claras que me permita lograr mi objetivo, no ejecutes ningún desarrollo hasta que yo no lo autorice      

# Recursos                                                  
1. Provider de Datadog para Terraform: https://registry.terraform.io/providers/DataDog/datadog/latest/docs                                               
2. Blog post para uso de Datadog con Terrafor: https://www.datadoghq.com/blog/managing-datadog-with-terraform/#deploy-datadog-with-terraform-today       
3. Configuración de integración de AWS-Datadog con Terraform
"
```

### Prompt #2: Prompt para guardar el plan

```markdown
guarda el plan en @docs/plan.md
```

**Plan de implementación:** [Plan con subtareas y bitácora de implementación](../docs/plan.md)

### Prompt #3: Prompt para corrección de tipo de instancia en AWS 

```markdown
Quiero además que corrijas el plan de ejecución. Yo tengo una instancia t2.micro, no usaré 2 instancias EC2: backend (t2.micro), frontend (t2.medium) tal como hoy está definido en la configuración de terraform. Esto también debemos modificarlo 
```

### Prompt #4 Prompt para aclarar duda de configuración de propiedades en .env para AWS

```markdown
En ### **FASE 1: Configuración Segura de Credenciales** ⏱️ 1-2 horas dices que vas a configurar el .env para la definición de api-key de Datadog (en local). No necesitamos hacer lo mismo para el access-key y el secret de mi cuenta de AWS? 
```

### Prompt #5 Prompt para refinar el alcance del plan de trabajo

```markdown
quiero que audites el plan y dejes solo las tareas necesiras para que la integración con AWS y Datadog por medio de los manifiestos declarativos de Terraform, funcionen correctamente. Por ejemplo, el paso: Crear terraform.tfvars.example no lo veo relavante. Prioriza la funcionalidad por favor, así aceleramos la entrega de valor    
```

### Prompt #6 Prompt para ejecutar plan de trabajo

```markdown
/sc:implement is running… --persona-devops --persona-backend --c7 --seq --think --validate  "Toma el plan de ejecución doumentado en @docs/plan.md e inicia con la ejecución de la Fase 1. No pases a la
 siguiente fase, hasta que yo apruebe paso a paso, la ejecución de actividades de desarrollo."
```

### Prompt #7: Prompt con dudas de la ejecución de la fase#1 del plan

```markdown
* La configuración regional incorrecta que encontraste, debes arreglarla, esa fue parte de mis instrucciones
* Ya tengo las key de datadog, pero no tengo claro donde las debo poner 
* Las credenciales de AWS ya las he configurado localmente con aws configure
```

### Prompt #8: Prompts reiterados por error en autenticación a la consola de Datadog

```markdown
Acabo de generar de ceros desde la consola de Datadog, un nuevo Api Key, acá te dejo el request que estoy intentando ahcer desde postman, pero me está dando forbidden [Image #1] [Image #2] acá el curl: 

curl --location 'https://api.datadoghq.com/api/v1/validate' --header 'Accept: application/json' --header 'DD-API-KEY: bbb353267294609a9f0ed25de9d784af'
```

### Prompt #9: Prompt para corregir problema de seguridad en secrets hardcodeados

```markdown
Mmm no, no me gusta así, deja entonces terraform.tfvars pero incluyelo en gitignore para no sincronizar las secret de terraform
```

### Prompt #9: Audtoria de archivos .tf

```markdown
/sc:analyze is running…  --persona-devops --think-hard --validate --c7 --seq Antes de continuar, esta base de código ya contaba con algunos archivos de terraform (.tf) dentro de la carpeta @tf. 

Excluyendo los archivos que creaste en la misma carpeta producto de la ejecución de la fase 1 y 2, quiero que audites la pertinencia del resto de archivos, validando posibles conflictos en la ejecución del plan de terraform y refinando la implementación en busca de simplicidad. De modo, que si detectas un sobreproceso o sobreprovisión de recursos, descartes lo que esté de más (sin afectar la funcionalidad y el resultado esperado: Desplegar este monorepo en la instancia ec2 definida y conectarlo a la herramienta de observabilidad: Datadog)
```

#### Hallazgos
```markdown
🔍 AUDITORÍA CRÍTICA: Sobreprovisionamiento Detectado

  ⚠️ CONFLICTO MAYOR: La infraestructura existente NO cumple tus requisitos:

  Problema 1: DOBLE INSTANCIA

  - Existente: 2 instancias separadas (backend + frontend)
  - Tu requisito: 1 sola instancia t2.micro
  - Costo extra: ~$17/mes innecesarios

  Problema 2: COMPLEJIDAD INNECESARIA

  - S3 bucket para distribución de código (sobreprovisionado)
  - Scripts separados para cada instancia
  - 2 Security Groups distintos
  - IAM roles para acceso S3 (no necesario en single instance)

  Problema 3: CONFLICTOS TÉCNICOS

  - Security groups references conflictarían
  - IAM policies duplicadas con nuestros roles Datadog
  - Scripts user_data incompatibles con arquitectura single-instance

  🎯 PROPUESTA DE SIMPLIFICACIÓN

  ELIMINAR (Archivos innecesarios):
  - s3.tf - Bucket S3 innecesario para single instance
  - iam.tf - Roles S3 sobreprovisionados
  - scripts/ completo - User data scripts separados
  - security_groups.tf - SGs duales innecesarios

  MANTENER Y REFACTORIZAR:
  - ec2.tf → Convertir a single instance
  - provider.tf ✅ (ya configurado)
  - variables.tf ✅ (ya configurado)
  - datadog-*.tf ✅ (nuestros archivos)

  BENEFICIOS:
  - 🏗️ Simplicidad: Single instance architecture
  - 💰 Costo: $8.5/mes vs $25.5/mes
  - 🔧 Mantenimiento: Configuración unificada
  - 🚀 Deploy: Código directo sin S3
```

### Prompt #9: Aplicar cambios de auditoria de archivos .tf

```markdown
Aplica todos los cambios identificados
```

### Prompt #10: Configuración para despliegue de aplicación en instancia

```markdown
/sc:implement --persona-devops --persona-backend --persona-architect --ultrathink --validate --c7 necesito que el frontend, backend y base de datos de la aplicación, quede desplegado en la instancia ec2 con terraform y quede disponible para consumo desde internet por ip/puerto. Esto implica
que las reglas de salida de los puertos correspondientes, queden implícitas en la configuración del grupo de seguridad. Para desplegar la base de datos dentro de la instancia, fíjate de como se está dockerizando todo en @docker-compose.yml ya que allí verás que se usan los valores de las credenciales de base de datos definidas en .env. Por otro lado, es importante que corras la migración de base
de datos que está en @backend/ para que las tablas y sus datos queden creadas y disponibles
```

### Prompt #11: Verificación de monitoreo en consola de Datadog

```markdown
mi objetivo principal, que es la implementación de la observabilidad con Datadog, como la verifico? como se que se están ingestando logs de monitoreo? si entro a la consola de Datadog, no veo nada que haga referencia a mi instancia EC2 [Image #1] 
```

### Prompt #12: Limpieza de archivos innecesarios y actualización del README y archivo de plan

```markdown
actualiza @docs/plan.md con el estado de tareas terminadas hasta ahora y complementa el @README.md con las instrucciones de deploy de la aplicación con terraform @DEPLOYMENT_STATUS.md y @FULL_STACK_DEPLOYMENT_STATUS.md no los necesito, contaminan mi base de código
```

### Prompt #13: Duda del comportamiento del deploy con Terraform para instancia EC2 apagada

```markdown
ahora mismo tengo mi instancia ec2 apagada, anoche la apagué para no incurrir en gastos. Si yo tengo todo desplegado en esa instancia, que comando de terrafom desde consola puedo usar para encenderla? por otro lado, los contenedores de aplicación que quedaron desplegados con docker compose, inician como servicio del sistema operativo, de modo que no debo inicializar a mano?
```

### Prompt #14: Problema con despiegue de aplicación ficticia en instancia EC2

```markdown
El que hayas definido un backend y un frontend ficticios porque el job de incluye hacer clone del repo, está muy mal, debe ser mi código el que corra en la nube, nada de crear un frontend y y backend nuevo si es que ya lo tengo en mi repositorio! esto nunca debió hacerse desde un principio. Incluyamos el paso de hacer clone del repositorio y preparar todo el deploy con docker-componse. Debe subir el frontend, el backend y la base de datos con los datos sincronizados de la migración de prisma. Todo debe estar realmente conectado! 
```








Tengo un par de dudas con la visualización de los registros de mi aplicaciój en Datadog: 
1. En la parte de APM -> Services, no aparece mi servicio, puedo activarlo con la configuración del provider de datadog o la configuración de mis manifiestos?  
   
2. No veo en que parte puedo ver los logs de la aplicación, tanto los de frontend como los de backend desde Datadog. Si entro a: Logs -> Explorer, no sale nada




