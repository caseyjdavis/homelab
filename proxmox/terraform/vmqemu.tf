resource "proxmox_vm_qemu" "your-vm" {
  
  # -- General settings

  name = "vm-name"
  desc = "description"
  agent = 1  # <-- (Optional) Enable QEMU Guest Agent
  target_node = "cargo"  # <-- Change to the name of your Proxmox node (if you have multiple nodes)
  tags = "homelab"
  vmid = "500"

  # -- Template settings

  clone = "ubuntu-2404-cloudinit"  # <-- Change to the name of the template or VM you want to clone
  full_clone = true  # <-- (Optional) Set to "false" to create a linked clone

  # -- Boot Process

  onboot = true 
  startup = ""  # <-- (Optional) Change startup and shutdown behavior
  automatic_reboot = false  # <-- Automatically reboot the VM after config change

  # -- Hardware Settings

  qemu_os = "other"
  bios = "ovmf"
  cores = 2
  sockets = 1
  cpu_type = "host"
  memory = 2048
  balloon = 2048  # <-- (Optional) Minimum memory of the balloon device, set to 0 to disable ballooning
  

  # -- Network Settings

  network {
    id     = 0  # <-- ! required since 3.x.x
    bridge = "vmbr0"
    model  = "virtio"
  }

  # -- Disk Settings
  
  scsihw = "virtio-scsi-single"  # <-- (Optional) Change the SCSI controller type, since Proxmox 7.3, virtio-scsi-single is the default one         
  
  disks {  # <-- ! changed in 3.x.x
    ide {
      ide0 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          storage = "local-lvm"
          size = "32G"  # <-- Change the desired disk size, ! since 3.x.x size change will trigger a disk resize
          iothread = true  # <-- (Optional) Enable IOThread for better disk performance in virtio-scsi-single
          replicate = false  # <-- (Optional) Enable for disk replication
        }
      }
    }
  }

  # Most cloud-init images require a serial device for their display
  serial {
    id = 0
  }

  # -- Cloud Init Settings

  ipconfig0 = "ip=10.0.60.27/24,gw=10.0.60.1"  # <-- Change to your desired IP configuration
  nameserver = "10.0.60.1"  # <-- Change to your desired DNS server
  ciuser = "casdavis" # <-- Change to your desired username
  # cipassword = "password"  # <-- (Optional) Change to your desired password
  sshkeys = var.PUBLIC_SSH_KEY  # <-- (Optional) Change to your public SSH key
}
