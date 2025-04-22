FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

COPY prisma/schema.prisma prisma/schema.prisma
RUN npx prisma generate


RUN npm install

COPY . .

EXPOSE 5000

CMD ["npm", "run", "start"]
