import axios from "axios";

export default async function handler(req, res) {
  const consumerKey = process.env.MPESA_CONSUMER_KEY;
  const consumerSecret = process.env.MPESA_CONSUMER_SECRET;

  const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString("base64");

  try {
    const response = await axios.get(
      "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      {
        headers: { Authorization: `Basic ${auth}` },
      }
    );
    res.status(200).json(response.data);
  } catch (error) {
    console.error(error.response?.data || error.message);
    res.status(500).json({ error: "Failed to generate access token" });
  }
}
