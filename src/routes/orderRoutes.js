import express from "express";
import { createOrder, getOrder, getOrderById, getOrderStats } from "../controllers/orderController.js";
import { verifyToken } from "../middleware/middleware.js";

const router = express.Router();

router.post("/", verifyToken, createOrder);
router.get("/stats", verifyToken, getOrderStats);
router.get("/", verifyToken, getOrder);
router.get("/:id", verifyToken, getOrderById);

export default router;
