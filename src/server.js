import express from "express";
import dotenv from "dotenv";
import authRoutes from "./routes/authRoutes.js"
import orderRoutes from "./routes/orderRoutes.js"
import path from "path";
import { fileURLToPath } from 'url';

dotenv.config();

const app = express();
app.use(express.json());

app.use("/api/auth", authRoutes);

app.use("/api/order", orderRoutes);
const PORT = process.env.PORT || 5000;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

app.get('/swagger.yaml', (req, res) => {
  const filePath = path.join(__dirname, 'swagger-output.yaml');
  res.sendFile(filePath);  // Kirimkan file .json
});
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
