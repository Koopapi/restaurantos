# RestaurantOS backend — Node + Express + ws (store en memoria, piloto).
# Imagen ligera de producción: instala solo dependencias de runtime y corre
# como usuario sin privilegios.
FROM node:20-alpine AS base

ENV NODE_ENV=production

WORKDIR /app

# Capa de dependencias (se cachea mientras el lockfile no cambie).
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Código de la aplicación.
COPY src ./src

EXPOSE 4000

# wget (busybox) viene en alpine; lo usa el healthcheck de compose.
USER node

CMD ["node", "src/server.js"]
