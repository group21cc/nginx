# Use the official nginx base image
FROM nginx:1.25-alpine

# Remove the default nginx index page
RUN rm -rf /usr/share/nginx/html/*

# Copy your custom application files into the container
# Assuming you have index.html (and maybe css/js) in your repo
COPY . /usr/share/nginx/html/

# Expose port 80 for the web server
EXPOSE 80

# Start nginx (default CMD in base image is fine)
CMD ["nginx", "-g", "daemon off;"]
