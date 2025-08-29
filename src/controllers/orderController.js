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
    // Ambil query parameters untuk pagination dan filter
    const { page = 1, limit = 10, name, minQuantity, maxQuantity } = req.query;
    
    // Convert ke integer
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Build filter object
    const where = {};
    if (name) {
      where.name = {
        contains: name,
        mode: 'insensitive'
      };
    }
    if (minQuantity || maxQuantity) {
      where.quantity = {};
      if (minQuantity) where.quantity.gte = parseInt(minQuantity);
      if (maxQuantity) where.quantity.lte = parseInt(maxQuantity);
    }

    // Ambil orders dengan pagination dan filter
    const [orders, totalCount] = await Promise.all([
      prisma.ordedrs.findMany({
        where,
        orderBy: {
          id: 'desc'
        },
        skip,
        take: limitNum
      }),
      prisma.ordedrs.count({ where })
    ]);

    // Calculate pagination info
    const totalPages = Math.ceil(totalCount / limitNum);
    const hasNextPage = pageNum < totalPages;
    const hasPrevPage = pageNum > 1;

    // Return response yang konsisten untuk frontend
    res.status(200).json({ 
      message: "Berhasil mengambil data orders", 
      data: orders,
      pagination: {
        currentPage: pageNum,
        totalPages,
        totalCount,
        hasNextPage,
        hasPrevPage,
        limit: limitNum
      }
    });
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ message: "Terjadi kesalahan saat mengambil data orders", error: error.message });
  }
};

export const getOrderById = async (req, res) => {
  const { id } = req.params;

  try {
    const order = await prisma.ordedrs.findUnique({
      where: {
        id: parseInt(id)
      }
    });

    if (!order) {
      return res.status(404).json({ message: "Order tidak ditemukan" });
    }

    res.status(200).json({ 
      message: "Berhasil mengambil data order", 
      data: order 
    });
  } catch (error) {
    console.error('Error fetching order by ID:', error);
    res.status(500).json({ message: "Terjadi kesalahan saat mengambil data order", error: error.message });
  }
};

export const getOrderStats = async (req, res) => {
  try {
    const [totalOrders, totalQuantity, avgQuantity] = await Promise.all([
      prisma.ordedrs.count(),
      prisma.ordedrs.aggregate({
        _sum: {
          quantity: true
        }
      }),
      prisma.ordedrs.aggregate({
        _avg: {
          quantity: true
        }
      })
    ]);

    res.status(200).json({
      message: "Berhasil mengambil statistik orders",
      data: {
        totalOrders,
        totalQuantity: totalQuantity._sum.quantity || 0,
        averageQuantity: Math.round((avgQuantity._avg.quantity || 0) * 100) / 100
      }
    });
  } catch (error) {
    console.error('Error fetching order stats:', error);
    res.status(500).json({ message: "Terjadi kesalahan saat mengambil statistik orders", error: error.message });
  }
};
