packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.4.0"
      source  = "github.com/digitalocean/digitalocean"
    }
  }
}

# ---------------------------------------------------------------------------
# Variables — override via environment or -var flag
# ---------------------------------------------------------------------------
variable "do_token" {
  type        = string
  description = "DigitalOcean API token (set via DIGITALOCEAN_TOKEN env var)"
  sensitive   = true
  default     = env("DIGITALOCEAN_TOKEN")
}

variable "app_version" {
  type    = string
  default = "3.0.1"
}

variable "build_region" {
  type    = string
  default = "nyc3"
}

# ---------------------------------------------------------------------------
# Source image — Ubuntu 22.04 LTS
# ---------------------------------------------------------------------------
source "digitalocean" "hashtagcms" {
  api_token    = var.do_token
  image        = "ubuntu-22-04-x64"
  region       = var.build_region
  size         = "s-2vcpu-4gb"
  ssh_username = "root"

  snapshot_name = "hashtagcms-${var.app_version}-{{timestamp}}"

  # Distribute snapshot to multiple regions after build
  snapshot_regions = [
    "nyc1", "nyc3",
    "sfo3",
    "ams3",
    "sgp1",
    "lon1",
    "fra1",
    "tor1",
    "blr1",
  ]

  tags = ["hashtagcms", "marketplace", "cms"]
}

# ---------------------------------------------------------------------------
# Build steps
# ---------------------------------------------------------------------------
build {
  sources = ["source.digitalocean.hashtagcms"]

  # 1. System packages + runtimes
  provisioner "shell" {
    script          = "scripts/01-base.sh"
    execute_command = "chmod +x {{ .Path }}; bash {{ .Path }}"
  }

  # 2. Application code + assets
  provisioner "shell" {
    script          = "scripts/02-app.sh"
    execute_command = "chmod +x {{ .Path }}; bash {{ .Path }}"
  }

  # 3. Nginx virtual host
  provisioner "shell" {
    script          = "scripts/03-nginx.sh"
    execute_command = "chmod +x {{ .Path }}; bash {{ .Path }}"
  }

  # 4. Copy the first-run (cloud-init per-instance) script into the image
  provisioner "file" {
    source      = "first-run/001-hashtagcms.sh"
    destination = "/tmp/001-hashtagcms.sh"
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /var/lib/cloud/scripts/per-instance",
      "mv /tmp/001-hashtagcms.sh /var/lib/cloud/scripts/per-instance/001-hashtagcms.sh",
      "chmod +x /var/lib/cloud/scripts/per-instance/001-hashtagcms.sh",
    ]
  }

  # 5. Final cleanup — sanitize before snapshot
  provisioner "shell" {
    script          = "scripts/99-cleanup.sh"
    execute_command = "chmod +x {{ .Path }}; bash {{ .Path }}"
  }
}
