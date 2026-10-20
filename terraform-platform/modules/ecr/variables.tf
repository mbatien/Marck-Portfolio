variable "name" {
  description = "Repository name"
  type        = string
}

variable "force_delete" {
  description = "Allow terraform destroy/delete the repository even if it contains images (dev)."
  type        = bool
  default     = false
}

variable "keep_last_images" {
  description = "How many images to keep before older ones expire."
  type        = number
  default     = 30
}
