const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.database();

// Hàm bật/tắt đèn dựa trên lịch trình
exports.scheduleLedControl = functions.pubsub
    .schedule("every 1 minutes").onRun(async (context) => {
      const now = new Date();
      //   const currentTime = `${now.getHours()}:${now.getMinutes()}`;

      // Lấy tất cả các lịch trình từ cơ sở dữ liệu
      const schedulesSnapshot = await db.ref("schedules").once("value");

      schedulesSnapshot.forEach((childSnapshot) => {
        const schedule = childSnapshot.val();
        const scheduleTime = new Date(schedule.time);

        // Nếu thời gian hiện tại khớp với thời gian đã đặt
        if (
          schedule.isActive &&
            scheduleTime.getHours() === now.getHours() &&
            scheduleTime.getMinutes() === now.getMinutes()
        ) {
          // Thực hiện cập nhật trạng thái đèn
          const updates = {};
          if (schedule.isOnSetting) {
            if (schedule.selectedLEDs[0]) {
              updates["Light/Led1"] = true;
            }
            if (schedule.selectedLEDs[1]) {
              updates["Light/Led2"] = true;
            }
          } else {
            if (schedule.selectedLEDs[0]) {
              updates["Light/Led1"] = false;
            }
            if (schedule.selectedLEDs[1]) {
              updates["Light/Led2"] = false;
            }
          }
          // Cập nhật Firebase Database với trạng thái mới
          db.ref().update(updates);
        }
      });

      return null;
    });
