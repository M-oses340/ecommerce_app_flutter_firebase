import express from "express";
import serverless from "serverless-http";

const app = express();
app.use(express.json());

// ✅ Root route
app.get("/", (req, res) => res.send("✅ M-Pesa Backend is Running"));

// ✅ Minimal STK push endpoint (logs requests, responds immediately)
app.post("/stkpush", (req, res) => {
  const { phone, amount } = req.body;
  console.log("STK push request received:", phone, amount);
  res.json({ status: "received", message: "STK push request received" });
});

// ✅ Callback endpoint (logs requests, responds immediately)
app.post("/callback", (req, res) => {
  console.log("Callback received:", req.body);
  res.json({ message: "Callback received successfully" });
});

// ✅ Export for Vercel
export default serverless(app);
