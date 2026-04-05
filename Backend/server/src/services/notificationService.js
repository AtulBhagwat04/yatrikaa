const admin = require('../config/firebase');

class NotificationService {
  /**
   * Send a notification to a specific user's FCM token
   * @param {string} fcmToken - The target device token
   * @param {Object} notification - { title: string, body: string }
   * @param {Object} data - Additional data to send (optional)
   */
  async sendToToken(fcmToken, notification, data = {}) {
    if (!fcmToken) {
      console.warn('[NotificationService] No token provided for notification');
      return;
    }

    try {
      const message = {
        token: fcmToken,
        notification,
        data: this._serializeData(data),
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default'
            }
          }
        }
      };

      const response = await admin.messaging().send(message);
      console.log('[NotificationService] Successfully sent message:', response);
      return response;
    } catch (error) {
      console.error('[NotificationService] Error sending message to token:', error.message);
      throw error;
    }
  }

  /**
   * Send a notification to multiple users
   * @param {Array<string>} tokens - Array of device tokens
   * @param {Object} notification - { title: string, body: string }
   * @param {Object} data - Additional data to send (optional)
   */
  async sendToMultipleTokens(tokens, notification, data = {}) {
    if (!tokens || tokens.length === 0) return;

    try {
      const message = {
        tokens,
        notification,
        data: this._serializeData(data),
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`[NotificationService] Multicast attempt: ${response.successCount} success, ${response.failureCount} failure`);
      return response;
    } catch (error) {
      console.error('[NotificationService] Error sending multicast message:', error.message);
    }
  }

  /**
   * Send a notification to a topic
   * @param {string} topic - The target topic name
   * @param {Object} notification - { title: string, body: string }
   * @param {Object} data - Additional data to send (optional)
   */
  async sendToTopic(topic, notification, data = {}) {
    try {
      const message = {
        topic,
        notification,
        data: this._serializeData(data),
      };

      const response = await admin.messaging().send(message);
      console.log(`[NotificationService] Topic message [${topic}] sent:`, response);
      return response;
    } catch (error) {
      console.error(`[NotificationService] Error sending topic message [${topic}]:`, error.message);
    }
  }

  /**
   * Helper to ensure all data values are strings (required by FCM)
   */
  _serializeData(data) {
    const serialized = {};
    for (const key in data) {
      if (typeof data[key] === 'object') {
        serialized[key] = JSON.stringify(data[key]);
      } else {
        serialized[key] = String(data[key]);
      }
    }
    return serialized;
  }
}

module.exports = new NotificationService();
