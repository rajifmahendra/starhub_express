import jwt from "jsonwebtoken";

export const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1]; // Ambil token dari header
  
  if (!token) {
    return res.status(401).json({ message: "Akses ditolak! Token tidak ditemukan." });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET); // Verifikasi token
    req.user = decoded; // Simpan data user yang sudah decode ke req.user
    next(); // Lanjut ke controller berikutnya
  } catch (error) {
    return res.status(403).json({ message: "Token tidak valid!", error: error.message });
  }
};
