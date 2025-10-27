import express from "express";
import cors from "cors";
import mpesaRoutes from "./routes/mpesa.js";

const app = express();
app.use(express.json());
app.use(cors());

app.use("/api/mpesa", mpesaRoutes);

app.get("/", (req, res) => res.send("M-Pesa & Stripe backend running"));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server started on port ${PORT}`));
