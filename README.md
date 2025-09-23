# LTI - Sistema de Seguimiento de Talento

Este proyecto es una aplicación full-stack con un frontend en React y un backend en Express usando Prisma como un ORM. El frontend se inicia con Create React App y el backend está escrito en TypeScript.

## Explicación de Directorios y Archivos

- `backend/`: Contiene el código del lado del servidor escrito en Node.js.
  - `src/`: Contiene el código fuente para el backend.
    - `index.ts`: El punto de entrada para el servidor backend.
    - `application/`: Contiene la lógica de aplicación.
    - `domain/`: Contiene la lógica de negocio.
    - `infrastructure/`: Contiene código que se comunica con la base de datos.
    - `presentation/`: Contiene código relacionado con la capa de presentación (como controladores).
    - `routes/`: Contiene las definiciones de rutas para la API.
    - `tests/`: Contiene archivos de prueba.
  - `prisma/`: Contiene el archivo de esquema de Prisma para ORM.
  - `tsconfig.json`: Archivo de configuración de TypeScript.
- `frontend/`: Contiene el código del lado del cliente escrito en React.
  - `src/`: Contiene el código fuente para el frontend.
  - `public/`: Contiene archivos estáticos como el archivo HTML e imágenes.
  - `build/`: Contiene la construcción lista para producción del frontend.
- `.env`: Contiene las variables de entorno.
- `docker-compose.yml`: Contiene la configuración de Docker Compose para gestionar los servicios de tu aplicación.
- `README.md`: Este archivo, contiene información sobre el proyecto e instrucciones sobre cómo ejecutarlo.

## Estructura del Proyecto

El proyecto está dividido en dos directorios principales: `frontend` y `backend`.

### Frontend

El frontend es una aplicación React y sus archivos principales están ubicados en el directorio `src`. El directorio `public` contiene activos estáticos y el directorio `build` contiene la construcción de producción de la aplicación.

### Backend

El backend es una aplicación Express escrita en TypeScript. El directorio `src` contiene el código fuente, dividido en varios subdirectorios:

- `application`: Contiene la lógica de aplicación.
- `domain`: Contiene los modelos de dominio.
- `infrastructure`: Contiene código relacionado con la infraestructura.
- `presentation`: Contiene código relacionado con la capa de presentación.
- `routes`: Contiene las rutas de la aplicación.
- `tests`: Contiene las pruebas de la aplicación.

El directorio `prisma` contiene el esquema de Prisma.

Tienes más información sobre buenas prácticas utilizadas en la [guía de buenas prácticas](./backend/ManifestoBuenasPracticas.md).

Las especificaciones de todos los endpoints de API los tienes en [api-spec.yaml](./backend/api-spec.yaml).

La descripción y diagrama del modelo de datos los tienes en [ModeloDatos.md](./backend/ModeloDatos.md).


## Primeros Pasos

Para comenzar con este proyecto, sigue estos pasos:

1. Clona el repositorio.
2. Instala las dependencias para el frontend y el backend:
```sh
cd frontend
npm install

cd ../backend
npm install
```
3. Construye el servidor backend:
```
cd backend
npm run build
```
4. Inicia el servidor backend:
```
cd backend
npm start
```
5. En una nueva ventana de terminal, construye el servidor frontend:
```
cd frontend
npm run build
```
6. Inicia el servidor frontend:
```
cd frontend
npm start
```

El servidor backend estará corriendo en http://localhost:3010 y el frontend estará disponible en http://localhost:3000.

## Docker y PostgreSQL

Este proyecto usa Docker para ejecutar una base de datos PostgreSQL. Así es cómo ponerlo en marcha:

Instala Docker en tu máquina si aún no lo has hecho. Puedes descargarlo desde aquí.
Navega al directorio raíz del proyecto en tu terminal.
Ejecuta el siguiente comando para iniciar el contenedor Docker:
```
docker-compose up -d
```
Esto iniciará una base de datos PostgreSQL en un contenedor Docker. La bandera -d corre el contenedor en modo separado, lo que significa que se ejecuta en segundo plano.

Para acceder a la base de datos PostgreSQL, puedes usar cualquier cliente PostgreSQL con los siguientes detalles de conexión:
 - Host: localhost
 - Port: 5432
 - User: postgres
 - Password: password
 - Database: mydatabase

Por favor, reemplaza User, Password y Database con el usuario, la contraseña y el nombre de la base de datos reales especificados en tu archivo .env.

Para detener el contenedor Docker, ejecuta el siguiente comando:
```
docker-compose down
```

Para generar la base de datos utilizando Prisma, sigue estos pasos:

1. Asegúrate de que el archivo `.env` en el directorio raíz del backend contenga la variable `DATABASE_URL` con la cadena de conexión correcta a tu base de datos PostgreSQL. Si no te funciona, prueba a reemplazar la URL completa directamente en `schema.prisma`, en la variable `url`.

2. Abre una terminal y navega al directorio del backend donde se encuentra el archivo `schema.prisma` y `seed.ts`.

3. Ejecuta los siguientes comandos para generar la estructura de prisma, las migraciones a tu base de datos y poblarla con datos de ejemplo:
```
npx prisma generate
npx prisma migrate dev
ts-node seed.ts
```

Una vez has dado todos los pasos, deberías poder guardar nuevos candidatos, tanto via web, como via API, verlos en la base de datos y obtenerlos mediante GET por id. 

```
POST http://localhost:3010/candidates
{
    "firstName": "Albert",
    "lastName": "Saelices",
    "email": "albert.saelices@gmail.com",
    "phone": "656874937",
    "address": "Calle Sant Dalmir 2, 5ºB. Barcelona",
    "educations": [
        {
            "institution": "UC3M",
            "title": "Computer Science",
            "startDate": "2006-12-31",
            "endDate": "2010-12-26"
        }
    ],
    "workExperiences": [
        {
            "company": "Coca Cola",
            "position": "SWE",
            "description": "",
            "startDate": "2011-01-13",
            "endDate": "2013-01-17"
        }
    ],
    "cv": {
        "filePath": "uploads/1715760936750-cv.pdf",
        "fileType": "application/pdf"
    }
}
```


---

## 🚀 Despliegue con Terraform (AWS + Datadog)

### Deployment Automatizado en AWS

Este proyecto incluye una configuración completa de Terraform para despliegue automático en AWS con observabilidad Datadog integrada.

#### 📋 Prerequisitos

1. **AWS CLI configurado**:
```bash
aws configure
# Configurar Access Key, Secret Key, Region: us-west-2
```

2. **Terraform instalado** (≥ 1.0):
```bash
# macOS
brew install terraform

# Verificar instalación
terraform version
```

3. **Credenciales Datadog**:
- API Key de Datadog
- Application Key de Datadog
- Cuenta en Datadog US3 (us3.datadoghq.com)

#### 🔧 Configuración Inicial

1. **Clonar y preparar el repositorio**:
```bash
git clone <repository-url>
cd AI4Devs-monitoring-JairoPolo
```

2. **Configurar variables de Terraform**:
```bash
# Copiar template de variables y completar credenciales
cd tf
cp terraform.tfvars.example terraform.tfvars

# Editar terraform.tfvars con sus credenciales reales:
# - AWS Access Key y Secret Key
# - Datadog API Key y App Key  
# - Verificar región us-west-2
```

3. **Inicializar Terraform**:
```bash
# Aplicar fix para Apple M1 (si aplica)
export GODEBUG=asyncpreemptoff=1

# Inicializar providers (desde directorio tf)
cd tf
terraform init
```

#### 🚀 Despliegue

**Deployment completo con un comando**:
```bash
# Desplegar infraestructura completa (desde directorio tf)
export GODEBUG=asyncpreemptoff=1  # Solo Apple M1
terraform apply -auto-approve
```

**Lo que se despliega automáticamente**:
- ✅ EC2 Instance (t2.micro) con Amazon Linux 2
- ✅ Security Groups configurados (ports 22, 3000, 8080, 5432)
- ✅ IAM Roles para integración Datadog
- ✅ Datadog Integration completa con AWS
- ✅ Docker + Docker Compose instalación automática
- ✅ PostgreSQL Database con schema y datos seed
- ✅ Backend Node.js con Prisma ORM
- ✅ Frontend React optimizado para producción
- ✅ Datadog Agent con APM y logs centralizados

#### 🌐 Acceso a la Aplicación

Después del deployment (8-12 minutos), tendrás acceso a:

```bash
# Obtener URLs de acceso
terraform output
```

**Endpoints disponibles**:
- **Frontend**: http://[PUBLIC_IP]:3000
- **Backend API**: http://[PUBLIC_IP]:8080
- **Health Check**: http://[PUBLIC_IP]:8080/health
- **SSH**: ssh -i ~/.ssh/AI4Devs.pem ec2-user@[PUBLIC_IP]

#### 📊 Monitoreo con Datadog

Una vez desplegado, puedes verificar el monitoreo en:

1. **Datadog Dashboard**: https://us3.datadoghq.com
2. **Infrastructure → Host Map**: Buscar tu instancia EC2
3. **APM → Services**: Ver métricas de performance
4. **Logs**: Logs centralizados de todos los servicios

**Tags de búsqueda**:
- env:production
- service:ai4devs-monorepo
- region:us-west-2

#### 🔄 Gestión del Despliegue

**Verificar estado**:
```bash
terraform show                    # Ver recursos desplegados
aws ec2 describe-instances         # Verificar instancia
curl http://[IP]:3000             # Probar frontend
curl http://[IP]:8080/health      # Probar backend
```

**Actualizar despliegue**:
```bash
# Para cambios menores (configuración, variables)
export GODEBUG=asyncpreemptoff=1  # Solo Apple M1
terraform plan                    # Ver cambios pendientes
terraform apply                   # Aplicar cambios

# Para cambios en manifiestos/user-data (RECOMENDADO)
export GODEBUG=asyncpreemptoff=1  # Solo Apple M1
terraform destroy -auto-approve && terraform apply -auto-approve

# Encender instancia apagada (mantiene datos)
export GODEBUG=asyncpreemptoff=1  # Solo Apple M1
terraform apply -auto-approve     # Solo encender sin recrear
```

**Limpiar recursos**:
```bash
export GODEBUG=asyncpreemptoff=1  # Solo Apple M1
terraform destroy -auto-approve
```

#### 🛠️ Solución de Problemas

**Apple M1 Timeout**:
```bash
export GODEBUG=asyncpreemptoff=1
```

**Verificar conectividad AWS**:
```bash
aws sts get-caller-identity --region us-west-2
```

**Ver logs de deployment**:
```bash
# SSH a la instancia (si tienes la key)
ssh -i ~/.ssh/AI4Devs.pem ec2-user@[PUBLIC_IP]
sudo tail -f /var/log/cloud-init-output.log
```

#### 📝 **Comandos para Ver Logs del Deployment**

Una vez conectado por SSH, puedes monitorear el deployment con estos comandos:

**1. Log Principal del Deployment**:
```bash
sudo tail -f /var/log/ai4devs-deployment.log
```

**2. Log Completo de Cloud-Init**:
```bash
sudo tail -f /var/log/cloud-init-output.log
```

**3. Log de Finalización**:
```bash
cat /var/log/deployment-complete.log
```

**4. Logs de Docker**:
```bash
cd /opt/ai4devs
# Ver logs de todos los contenedores
sudo docker logs -f ai4devs-backend-1
sudo docker logs -f ai4devs-frontend-1
sudo docker logs -f ai4devs-db-1
```

**6. Estado de Contenedores**:
```bash
cd /opt/ai4devs
sudo docker ps
sudo docker ps -a
```

**7. Logs del Sistema (Cloud-Init)**:
```bash
# Log completo de inicialización
sudo journalctl -u cloud-final -f

# Log de cloud-init
sudo cat /var/log/cloud-init.log
```

**8. Ver Logs en Tiempo Real Durante Deployment**:
```bash
# Deployment en progreso
sudo tail -f /var/log/ai4devs-deployment.log

# Ver múltiples logs simultáneamente
sudo tail -f /var/log/ai4devs-deployment.log /var/log/cloud-init-output.log
```

**9. Debug Commands**:
```bash
# Verificar estructura del repositorio clonado
ls -la /opt/ai4devs/

# Ver contenido del .env generado
cat /opt/ai4devs/.env

# Ver docker-compose generado
cat /opt/ai4devs/docker-compose.yml

# Ver Dockerfiles generados
cat /opt/ai4devs/backend/Dockerfile
cat /opt/ai4devs/frontend/Dockerfile
```

**🔍 Comando Recomendado para Monitoreo Completo**:
```bash
# Una vez conectado por SSH
sudo tail -f /var/log/ai4devs-deployment.log
```

*Este log contiene todas las etapas marcadas con timestamps desde el clone del repositorio hasta el deployment completo.*

#### 📁 Estructura Terraform

```
├── provider.tf              # Providers AWS y Datadog
├── variables.tf              # Variables de configuración
├── ec2.tf                   # Instancia EC2 con user-data
├── security_groups.tf       # Reglas de firewall
├── datadog-iam.tf          # IAM roles para Datadog
├── datadog-integration.tf   # Integración AWS-Datadog
├── outputs.tf              # URLs y información de acceso
└── terraform.tfvars        # Variables (NO incluir en git)
```

🎯 **Con este setup, tendrás un deployment completo de la aplicación con observabilidad enterprise-grade en menos de 15 minutos.**

---

## 📋 **APIs Disponibles**

### **Endpoints de la Aplicación** (Puerto 8080)

| Método | Endpoint | Descripción | Ejemplo |
|--------|----------|-------------|---------|
| **GET** | `/` | Health check básico | `curl http://[IP]:8080/` |
| **GET** | `/candidates` | Listar todos los candidatos | `curl http://[IP]:8080/candidates` |
| **GET** | `/candidates/:id` | Obtener candidato por ID | `curl http://[IP]:8080/candidates/1` |
| **POST** | `/candidates` | Crear nuevo candidato | Ver ejemplo abajo |
| **GET** | `/positions` | Listar todas las posiciones | `curl http://[IP]:8080/positions` |
| **GET** | `/positions/:id` | Obtener posición por ID | `curl http://[IP]:8080/positions/1` |
| **GET** | `/applications` | Listar todas las aplicaciones | `curl http://[IP]:8080/applications` |
| **GET** | `/companies` | Listar todas las compañías | `curl http://[IP]:8080/companies` |
| **GET** | `/employees` | Listar todos los empleados | `curl http://[IP]:8080/employees` |

### **Ejemplos de Uso**

**Consultar datos básicos:**
```bash
# Ver todos los candidatos
curl http://[PUBLIC_IP]:8080/candidates

# Ver todas las posiciones disponibles  
curl http://[PUBLIC_IP]:8080/positions

# Ver todas las compañías
curl http://[PUBLIC_IP]:8080/companies
```

**Crear un nuevo candidato:**
```bash
curl -X POST http://[PUBLIC_IP]:8080/candidates \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Juan",
    "lastName": "Pérez", 
    "email": "juan.perez@email.com",
    "phone": "555-0123",
    "address": "Calle Principal 123",
    "educations": [{
      "institution": "Universidad Nacional",
      "title": "Ingeniería de Sistemas",
      "startDate": "2020-01-01",
      "endDate": "2024-01-01"
    }],
    "workExperiences": [{
      "company": "Tech Corp",
      "position": "Desarrollador",
      "description": "Desarrollo web",
      "startDate": "2024-02-01"
    }]
  }'
```

### **URLs de Acceso**

Una vez desplegado, reemplaza `[PUBLIC_IP]` con la IP pública de tu instancia:

- **Frontend**: `http://[PUBLIC_IP]:3000`
- **Backend API**: `http://[PUBLIC_IP]:8080`
- **Ejemplo**: `http://44.252.128.128:8080/candidates`

ENDFILE < /dev/null