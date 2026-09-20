import Foundation

@main
struct UPIPaymentDetectorTests {
    static func main() {
        let query = "?mode=04&purpose=14&pa=merchant@axisbank&pn=Google&am=15000.00&amrule=MAX&recur=ASPRESENTED&txnType=CREATE&QRts=2026-09-20T13:45:02+05:30&sign=a%2Bb%3D&tn=upi://pay"
        let mandate = "upi://mandate" + query
        precondition(UPIPaymentDetector.isUPIPayment(mandate))
        precondition(QRContentClassifier.displayType(for: mandate) == "UPI Mandate")
        precondition(UPIPaymentDetector.paymentURLString(from: mandate) == mandate)
        for (app, prefix) in [("Google Pay", "gpay://upi/mandate"), ("PhonePe", "phonepe://mandate"), ("Paytm", "paytmmp://mandate")] {
            precondition(UPIPaymentDetector.appURLString(from: mandate, app: app) == prefix + query)
            precondition(UPIPaymentDetector.appURLString(from: " \nUPI://MANDATE" + query + "\n", app: app) == prefix + query)
        }
        precondition(UPIPaymentDetector.appURLString(from: mandate, app: "CRED") == nil)
        let payment = "upi://pay" + query
        precondition(QRContentClassifier.displayType(for: payment) == "UPI Payment")
        for (app, prefix) in [("Google Pay", "gpay://upi/pay"), ("PhonePe", "phonepe://upi/pay"), ("Paytm", "paytmmp://upi/pay"), ("CRED", "credpay://upi/pay"), ("BHIM", "bhim://upi/pay"), ("Amazon Pay", "amazonpay://upi/pay"), ("WhatsApp", "upi://pay")] {
            precondition(UPIPaymentDetector.appURLString(from: payment, app: app) == prefix + query)
        }
        for invalid in ["upi://payment?pa=a@b", "upi://mandate.evil?pa=a@b", "https://mandate?pa=a@b", "upi://mandate/other?pa=a@b", "plain text"] {
            precondition(!UPIPaymentDetector.isUPIPayment(invalid))
        }
        print("UPI detection and routing regression tests passed")
    }
}
