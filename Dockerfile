# from ligt wight secure base image 
FROM alpine:3.19

#set working directory inside the docker container 

WORKDIR /app

# copu application file into the container 

COPY app.sh .

RUN  chmod +x app.sh 

USER nobody 

CMD ["./app.sh"]

# make a note for this command and logics 