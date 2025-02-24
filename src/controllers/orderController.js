import { PrismaClient } from "@prisma/client";

import dotenv from "dotenv";

dotenv.config();
const prisma = new PrismaClient();

export const createOrder = async (req, res) => {
  const { name, quantity } = req.body;

  try {
    
    const newOrder = await prisma.ordedrs.create({
      data: { name,quantity }
    });

    res.status(201).json({ message: "Berhasil mendaftarkan order", user: newOrder });
  } catch (error) {
    res.status(500).json({ message: "Terjadi kesalahan", error });
  }
};

export const getOrder = async (req, res) => {


  try {
    // Cek apakah user ada
    const orders = await prisma.ordedrs.findMany();
    if (orders.length === 0) {
      return res.status(400).json({ message: "Belum ada order" });
    }


    res.status(200).json({orders });
  } catch (error) {
    res.status(500).json({ message: "Terjadi kesalahan", error });
  }
};
