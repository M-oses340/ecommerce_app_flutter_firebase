import express from "express";
import axios from "axios";
import dotenv from "dotenv";

dotenv.config();
const app = express();
app.use(express.json());

app.get("/", (req, res) => res.send("✅ M-Pesa Backend is Running"));

app.get("/token", async (req, res) => {
  try {
    const url = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials";
    const auth = Buffer.from(`${process.env.CONSUMER_KEY}:${process.env.CONSUMER_SECRET}`).toString("base64");
    const response = await axios.get(url, { headers: { Authorization: `Basic ${auth}` } });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: "Failed to get token" });
  }
});

app.post("/stkpush", async (req, res) => {
  try {
    const { phone, amount } = req.body;

    const tokenResponse = await axios.get(
      "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      { headers: { Authorization: `Basic ${Buffer.from(`${process.env.CONSUMER_KEY}:${process.env.CONSUMER_SECRET}`).toString("base64")}` } }
    );

    const accessToken = tokenResponse.data.access_token;

    const timestamp = new Date().toISOString().replace(/[^0-9]/g, "").slice(0, 14);
    const password = Buffer.from(`${process.env.SHORTCODE}${process.env.PASSKEY}${timestamp}`).toString("base64");

    const stkRequest = {
      BusinessShortCode: process.env.SHORTCODE,
      Password: password,
      Timestamp: timestamp,
      TransactionType: "CustomerPayBillOnline",
      Amount: amount,
      PartyA: phone,
      PartyB: process.env.SHORTCODE,
      PhoneNumber: phone,
      CallBackURL: `${process.env.PUBLIC_URL}/callback`,
      AccountReference: "EcommerceApp",
      TransactionDesc: "Payment for goods",
    };

    const response = await axios.post(
      "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
      stkRequest,
      { headers: { Authorization: `Bearer ${accessToken}` } }
    );

    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: "STK Push failed" });
  }
});

app.post("/callback", (req, res) => {
  console.log("🔔 Callback Data:", req.body);
  res.json({ message: "Callback received successfully" });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`✅ M-Pesa Backend running on port ${PORT}`));
