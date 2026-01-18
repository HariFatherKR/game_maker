/**
 * IdleFarm Roguelike - Mobile App
 *
 * React Native + Godot 모바일 앱 진입점
 */

import React, { useCallback } from 'react';
import {
  SafeAreaView,
  StatusBar,
  StyleSheet,
  Alert,
} from 'react-native';
import { GodotGame } from './src/components';
import { GodotBridge, GodotMessage, SaveGamePayload, PurchaseRequestPayload } from './src/services/godot';
import { useGodotEvent } from './src/hooks';

// =============================================================================
// App 컴포넌트
// =============================================================================

const App: React.FC = () => {
  /**
   * 세이브 요청 처리
   */
  const handleSaveGame = useCallback((message: GodotMessage<SaveGamePayload>) => {
    console.log('[App] Save game requested:', message.payload);
    // TODO: AsyncStorage 또는 클라우드에 저장
  }, []);

  /**
   * 구매 요청 처리
   */
  const handlePurchaseRequest = useCallback(
    async (message: GodotMessage<PurchaseRequestPayload>) => {
      const { productId } = message.payload;
      console.log('[App] Purchase requested:', productId);

      // TODO: react-native-iap로 실제 결제 처리
      // 임시로 성공 응답
      Alert.alert(
        'In-App Purchase',
        `Purchase ${productId}?`,
        [
          {
            text: 'Cancel',
            style: 'cancel',
            onPress: () => {
              GodotBridge.sendPurchaseResult(false, productId, 'User cancelled');
            },
          },
          {
            text: 'Buy',
            onPress: () => {
              GodotBridge.sendPurchaseResult(true, productId);
            },
          },
        ]
      );
    },
    []
  );

  /**
   * 알림 예약 요청 처리
   */
  interface NotificationPayload {
    title: string;
    body: string;
    delaySeconds: number;
  }

  const handleNotificationSchedule = useCallback(
    (message: GodotMessage<NotificationPayload>) => {
      console.log('[App] Notification schedule requested:', message.payload);
      // TODO: react-native-push-notification으로 예약
    },
    []
  );

  // Godot 이벤트 구독
  useGodotEvent('SAVE_GAME', handleSaveGame);
  useGodotEvent('PURCHASE_REQUEST', handlePurchaseRequest);
  useGodotEvent('NOTIFICATION_SCHEDULE', handleNotificationSchedule);

  /**
   * 게임 준비 완료
   */
  const handleGameReady = useCallback(() => {
    console.log('[App] Game is ready!');
  }, []);

  /**
   * 게임 에러
   */
  const handleGameError = useCallback((error: Error) => {
    console.error('[App] Game error:', error);
    Alert.alert('Error', 'Failed to load game. Please restart the app.');
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#1a1a1a" />
      <GodotGame
        onReady={handleGameReady}
        onError={handleGameError}
        showLoading={true}
      />
    </SafeAreaView>
  );
};

// =============================================================================
// 스타일
// =============================================================================

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1a1a1a',
  },
});

export default App;
