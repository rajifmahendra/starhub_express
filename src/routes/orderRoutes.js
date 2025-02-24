import express from "express";
import { createOrder, getOrder } from "../controllers/orderController.js";
import { verifyToken } from "../middleware/middleware.js";

const router = express.Router();

router.post("", verifyToken, createOrder);
router.get("", verifyToken, getOrder);

export default router;
