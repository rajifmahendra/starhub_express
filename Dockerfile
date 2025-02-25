# Gunakan Node.js versi terbaru sebagai base image
FROM node:18-alpine

# Set working directory di dalam container
WORKDIR /app

# Copy package.json dan package-lock.json terlebih dahulu (agar caching lebih optimal)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy Prisma schema sebelum menjalankan generate
COPY prisma/schema.prisma prisma/schema.prisma
RUN npx prisma generate


# Copy semua file ke dalam container
COPY . .


# Expose port aplikasi (default 3000)
EXPOSE 5000

# Perintah untuk menjalankan aplikasi
CMD ["npm", "run", "start"]
