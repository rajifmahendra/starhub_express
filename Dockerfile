FROM node:18-alpine

# Install required packages for better DAST testing
RUN apk add --no-cache \
    curl \
    wget \
    netcat-openbsd

WORKDIR /app

# Copy package files
COPY package*.json ./

# Copy prisma schema and generate client
COPY prisma/schema.prisma prisma/schema.prisma
RUN npx prisma generate

# Install dependencies
RUN npm install --production

# Copy application code
COPY . .

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Change ownership of app directory
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expose port
EXPOSE 5000

# Health check for DAST readiness
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:5000/api/auth/login || exit 1

# Start application
CMD ["npm", "run", "start"]
