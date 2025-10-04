import {setGlobalOptions} from "firebase-functions/v2";
import {onCall} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

setGlobalOptions({maxInstances: 10});
const SENDGRID_KEY = defineSecret("SENDGRID_KEY");

if (!admin.apps.length) {
  admin.initializeApp();
}

export const sendOtpEmail = onCall({secrets: [SENDGRID_KEY]},
  async (request) => {
    const {email} = request.data as { email: string };

    if (!email) throw new Error("Email is required");

    const sgMailModule = await import("@sendgrid/mail");
    const sgMail = sgMailModule.default;

    // ✅ Use the secret from Firebase
    sgMail.setApiKey(SENDGRID_KEY.value());

    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    await admin.firestore().collection("otps").doc(email).set({
      otp,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const htmlContent = `
<h2>RampGuard OTP</h2>
<p>Your one-time password is:</p>
<h1 style="color:blue">${otp}</h1>
<p>Expires in 5 minutes.</p>
`;

    const msg = {
      to: email,
      from: "rampguard@wcc-rampguard.com",
      subject: "Your OTP Code",
      html: htmlContent,
    };

    try {
      await sgMail.send(msg);
      return {success: true};
    } catch (error: unknown) {
      console.error("SendGrid error:", error);
      if (error instanceof Error) {
        console.error("SendGrid error:", error.message);
      } else {
        console.error("Unknown SendGrid error:", error);
      }
      logger.error("SendGrid error", error);
      throw new Error(error instanceof Error ? error.message : "Unknown error");
    }
  });

export const verifyOtp = onCall(async (request) => {
  const {email, otp} = request.data as { email: string; otp: string };

  if (!email || !otp) throw new Error("Email and OTP are required");

  const doc = await admin.firestore().collection("otps").doc(email).get();

  if (!doc.exists) return {success: false, message: "No OTP found"};

  const record = doc.data() as {
    otp: string;
    createdAt: FirebaseFirestore.Timestamp;
  };

  return record.otp === otp ?
    {success: true} :
    {success: false, message: "Invalid OTP"};
});
