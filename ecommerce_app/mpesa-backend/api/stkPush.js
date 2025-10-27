import axios from "axios";

export default async function handler(req, res) {
  const { phone, amount } = req.body;

  const shortcode = process.env.MPESA_SHORTCODE;
  const passkey = process.env.MPESA_PASSKEY;
  const timestamp = new Date()
    .toISOString()
    .replace(/[-:T.Z]/g, "")
    .substring(0, 14);

  const password = Buffer.from(shortcode + passkey + timestamp).toString("base64");

  try {
    // Get access token
    const tokenRes = await axios.get(
      `${process.env.MPESA_BASE_URL}/oauth/v1/generate?grant_type=client_credentials`,
      {
        auth: {
          username: process.env.MPESA_CONSUMER_KEY,
          password: process.env.MPESA_CONSUMER_SECRET,
        },
      }
    );

    const token = tokenRes.data.access_token;

    // STK Push
    const stkRes = await axios.post(
      `${process.env.MPESA_BASE_URL}/mpesa/stkpush/v1/processrequest`,
      {
        BusinessShortCode: shortcode,
        Password: password,
        Timestamp: timestamp,
        TransactionType: "CustomerPayBillOnline",
        Amount: amount,
        PartyA: phone,
        PartyB: shortcode,
        PhoneNumber: phone,
        CallBackURL: `${process.env.PUBLIC_URL}/api/callback`,
        AccountReference: "FlutterEcommerce",
        TransactionDesc: "Payment for goods",
      },
      {
        headers: { Authorization: `Bearer ${token}` },
      }
    );

    res.status(200).json(stkRes.data);
  } catch (error) {
    console.error(error.response?.data || error.message);
    res.status(500).json({ error: "STK push failed" });
  }
}
