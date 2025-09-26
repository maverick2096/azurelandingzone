variable "cfg" {
  type = object({
    name     = string
    location = string
    tags     = map(string)
  })
}
