service {
  name = "api"
  id = "api-v1"
  port = 9090
  
  connect { 
    sidecar_service {
      port = 20000
      
      check {
        name = "Connect Envoy Sidecar"
        tcp = "localhost:20000"
        interval ="10s"
      }

      proxy {
      }
    }  
  }
}