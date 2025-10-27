import express from "express";
import axios from "axios";
import dotenv from "dotenv";
dotenv.config();

const router = express.Router();

// Generate access token
async function getAccessToken() {
  const credentials = Buffer.from(`${process.env.CONSUMER_KEY}:${process.env.CONSUMER_SECRET}`).toString("base64");
  const response = await axios.get(
    "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
    { headers: { Authorization: `Basic ${credentials}` } }
  );
  return response.data.access_token;
}

// STK Push
router.post("/stkpush", async (req, res) => {
  try {
    const { phone, amount } = req.body;
    const token = await getAccessToken();

    const timestamp = new Date().toISOString().replace(/[-:TZ.]/g, "");
    const password = Buffer.from(`${process.env.SHORTCODE}${process.env.PASSKEY}${timestamp}`).toString("base64");

    const payload = {
      BusinessShortCode: process.env.SHORTCODE,
      Password: password,
      Timestamp: timestamp,
      TransactionType: "CustomerPayBillOnline",
      Amount: amount,
      PartyA: phone,
      PartyB: process.env.SHORTCODE,
      PhoneNumber: phone,
      CallBackURL: "https://your-render-app.onrender.com/api/mpesa/callback",
      AccountReference: "Ecommerce Flutter App",
      TransactionDesc: "Order Payment",
    };

    const response = await axios.post(
      "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
      payload,
      { headers: { Authorization: `Bearer ${token}` } }
    );

    res.json(response.data);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "STK Push failed" });
  }
});

// Callback
router.post("/callback", async (req, res) => {
  console.log("Callback received:", JSON.stringify(req.body, null, 2));
  res.json({ ResultCode: 0, ResultDesc: "Accepted" });
});

export default router;
