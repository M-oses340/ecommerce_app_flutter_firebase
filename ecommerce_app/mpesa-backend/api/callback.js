export default async function handler(req, res) {
  console.log("M-Pesa Callback Data:", req.body);

  // Here you can save to Firestore or your DB if you like.
  res.status(200).json({ ResultCode: 0, ResultDesc: "Accepted" });
}
