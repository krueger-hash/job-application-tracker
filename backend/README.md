# Backend Service for Job Application Tracker


Testing the backend service locally without localstack:
1. Go into the backend folder
1. Start the docker postgres container `docker-compose up -d postgres`
1. Start the backend service on local profile by running `mvn spring-boot:run -Plocal "-Dspring-boot.run.profiles=local"`