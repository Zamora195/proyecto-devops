# Usamos una imagen oficial de nginx muy ligera (basada en Alpine Linux)
FROM nginx:alpine

# Copiamos nuestra página web al directorio que sirve nginx
COPY index.html /usr/share/nginx/html/index.html
COPY style.css /usr/share/nginx/html/style.css

# Exponemos el puerto 80 (HTTP)
EXPOSE 80

# Comando para iniciar nginx
CMD ["nginx", "-g", "daemon off;"]