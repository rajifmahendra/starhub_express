import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";

dotenv.config();
const prisma = new PrismaClient();

export const register = async (req, res) => {
  const { email, password } = req.body;

  try {
    // Cek apakah email sudah terdaftar
    const existingUser = await prisma.users.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: "Email sudah digunakan" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Simpan user ke database
    const newUser = await prisma.users.create({
      data: { email, password: hashedPassword },
    });

    res.status(201).json({ message: "Registrasi berhasil", user: newUser });
  } catch (error) {
    res.status(500).json({ message: "Terjadi kesalahan", error });
  }
};

export const login = async (req, res) => {
  const { email, password } = req.body;

  try {
    // Cek apakah user ada
    const user = await prisma.users.findUnique({ where: { email } });
    if (!user) {
      return res.status(400).json({ message: "User tidak ditemukan" });
    }

    // Cek password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Password salah" });
    }

    // Generate JWT token
    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
      expiresIn: "1h",
    });

    res.status(200).json({ message: "Login berhasil", token });
  } catch (error) {
    res.status(500).json({ message: "Terjadi kesalahan", error });
  }
};
