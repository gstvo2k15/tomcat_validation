# Terraform: provider privado mediante Artifactory y gestión de secretos

## 1. Diagnóstico del error de `terraform init`

Terraform está intentando encontrar:

```text
registry.terraform.io/hashicorp/cibcloud
```

Sin embargo, en Artifactory el provider está organizado como:

```text
cib-ito/cibcloud/1.1.72/
```

Esto indica que Terraform está utilizando un namespace incorrecto.

Si en `providers.tf` existe únicamente algo parecido a:

```hcl
provider "cibcloud" {
}
```

sin declarar `required_providers`, Terraform puede asumir:

```text
hashicorp/cibcloud
```

### Solución

Declarar explícitamente el `source` del provider:

```hcl
terraform {
  required_providers {
    cibcloud = {
      source  = "cib-ito/cibcloud"
      version = "1.1.72"
    }
  }
}

provider "cibcloud" {
}
```

Después, `terraform init` debería intentar resolver:

```text
registry.terraform.io/cib-ito/cibcloud
```

lo que encaja con la estructura observada en Artifactory:

```text
public-terraformprovider/
└── cib-ito/
    └── cibcloud/
        └── 1.1.72/
```

---

## 2. Limpiar una inicialización previa

Después de corregir el `source`, limpiar la resolución anterior:

```bash
rm -rf .terraform
rm -f .terraform.lock.hcl
./terraform.exe init
```

> `.terraform.lock.hcl` debe versionarse normalmente. Solo se elimina aquí para regenerarlo después de corregir el `source` del provider.

---

## 3. Configuración de `terraform.rc`

La configuración del mirror:

```hcl
provider_installation {
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }

  network_mirror {
    url = "https://artifactory.cib.echonet/artifactory/api/terraform/public-terraformprovider/providers/"
  }
}
```

significa:

```text
No descargar providers directamente de registry.terraform.io
                            │
                            ▼
                     usar Artifactory
                            │
                            ▼
               public-terraformprovider
```

Por eso un error como:

```text
provider registry.terraform.io/hashicorp/cibcloud was not found
```

no implica necesariamente que el mirror esté roto.

Puede significar simplemente:

```text
Terraform busca:
hashicorp/cibcloud

Artifactory contiene:
cib-ito/cibcloud
```

El primer punto a corregir es el `source` de `required_providers`.

---

## 4. Diferencia entre `TF_TOKEN_*` y variables de Terraform

Una variable como:

```bash
export TF_TOKEN_artifactory_cib_echonet="..."
```

no es una variable normal de Terraform.

Es una variable especial del **Terraform CLI** utilizada para autenticarse contra ese hostname.

Por tanto, escribir esto en `terraform.tfvars`:

```hcl
TF_TOKEN_artifactory_cib_echonet = "secreto"
```

no sustituye al `export`.

Terraform lo interpretaría como una variable de entrada de la configuración, no como una credencial del CLI.

### Resumen

```text
TF_TOKEN_artifactory_cib_echonet
└── Terraform CLI
    └── autenticación contra Artifactory durante terraform init

terraform.tfvars
└── variables de Terraform
    └── utilizadas por módulos y providers durante la configuración
```

---

## 5. Guardar el token de Artifactory en `terraform.rc`

Para evitar el `export` del token, puede colocarse en el fichero CLI:

```hcl
credentials "artifactory.cib.echonet" {
  token = "TOKEN_NUEVO"
}

provider_installation {
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }

  network_mirror {
    url = "https://artifactory.cib.echonet/artifactory/api/terraform/public-terraformprovider/providers/"
  }
}
```

El fichero puede mantenerse fuera del repositorio, por ejemplo:

```text
C:\Users\h62043\terraform.rc
```

y referenciarse con:

```bash
export TF_CLI_CONFIG_FILE='C:\Users\h62043\terraform.rc'
```

o configurarse persistentemente en Windows.

### Importante

Si `terraform.rc` contiene el token:

```text
terraform.rc
└── contiene secreto
    └── NO debe subirse a Git
```

---

## 6. Variables sensibles del provider en `.tfvars`

Las credenciales utilizadas por el provider `cibcloud` sí pueden introducirse mediante variables de Terraform.

### `variables.tf`

```hcl
variable "cib_username" {
  type = string
}

variable "cib_password" {
  type      = string
  sensitive = true
}
```

### `terraform.tfvars`

```hcl
cib_username = "usuario"
cib_password = "password"
```

### `providers.tf`

```hcl
terraform {
  required_providers {
    cibcloud = {
      source  = "cib-ito/cibcloud"
      version = "1.1.72"
    }
  }
}

provider "cibcloud" {
  username = var.cib_username
  password = var.cib_password
}
```

Los nombres reales de los atributos (`username`, `password`, `token`, etc.) dependen de cómo esté implementado el provider `cibcloud`.

---

## 7. Separación de secretos

Conviene distinguir tres tipos:

```text
Token de Artifactory
│
└── terraform.rc / TF_TOKEN_*
    └── utilizado por Terraform CLI durante init

Credenciales de cibcloud
│
└── terraform.tfvars
    └── utilizadas por el provider

Private keys (*.key)
│
└── fichero externo
    └── nunca Git
```

---

## 8. `.gitignore` recomendado

```gitignore
# Terraform state
*.tfstate
*.tfstate.*

# Terraform local directory
.terraform/

# Sensitive variable files
*.tfvars
*.tfvars.json

# Terraform CLI config
terraform.rc
.terraformrc

# Certificates / private keys
*.key
*.pem
*.p12
*.pfx

# Terraform crashes
crash.log
crash.*.log

# Overrides
override.tf
override.tf.json
*_override.tf
*_override.tf.json
```

### No ignorar

```text
.terraform.lock.hcl
```

Este fichero debe versionarse.

---

## 9. Claves privadas

Un fichero como:

```text
iv2producers-tomcat-demo.key
```

no debe subirse a Git.

Por eso debe existir, como mínimo:

```gitignore
*.key
```

Un `.csr` normalmente no contiene la clave privada y puede versionarse técnicamente, aunque normalmente tampoco es necesario hacerlo.

---

## 10. Estructura recomendada

```text
C:\Users\h62043\
└── terraform.rc              # credencial de Artifactory, NO Git

tfpoc/
├── .gitignore
├── main.tf
├── providers.tf
├── variables.tf
├── terraform.tfvars          # secretos del provider, NO Git
└── .terraform.lock.hcl       # SÍ Git
```

### `providers.tf`

```hcl
terraform {
  required_providers {
    cibcloud = {
      source  = "cib-ito/cibcloud"
      version = "1.1.72"
    }
  }
}
```

### `C:\Users\h62043\terraform.rc`

```hcl
credentials "artifactory.cib.echonet" {
  token = "TOKEN_NUEVO"
}

provider_installation {
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }

  network_mirror {
    url = "https://artifactory.cib.echonet/artifactory/api/terraform/public-terraformprovider/providers/"
  }
}
```

### Reinicialización

```bash
rm -rf .terraform
rm -f .terraform.lock.hcl

export TF_CLI_CONFIG_FILE='C:\Users\h62043\terraform.rc'

./terraform.exe init
```

---

## 11. Punto principal a corregir

El indicio principal del error es:

```text
Terraform busca:
hashicorp/cibcloud

Artifactory contiene:
cib-ito/cibcloud
```

Por tanto, el primer cambio debe ser declarar correctamente:

```hcl
source = "cib-ito/cibcloud"
```

dentro de `required_providers`.
