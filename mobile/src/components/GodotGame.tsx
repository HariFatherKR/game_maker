/**
 * GodotGame - Godot 게임 뷰 컴포넌트
 *
 * React Native 앱 내에 Godot 게임을 렌더링합니다.
 */

import React, { useRef, useEffect, useCallback } from 'react';
import { StyleSheet, View, ActivityIndicator, Text } from 'react-native';
// NOTE: Enable when @borndotcom/react-native-godot is installed
// import { GodotView } from '@borndotcom/react-native-godot';
import type { GodotMessage } from '../services/godot';
import { useGodotConnection, useOfflineReward } from '../hooks';

// =============================================================================
// 타입 정의
// =============================================================================

interface GodotGameProps {
  /** PCK 파일 경로 */
  pckPath?: string;
  /** 로딩 중 표시 여부 */
  showLoading?: boolean;
  /** 에러 발생 시 콜백 */
  onError?: (error: Error) => void;
  /** 게임 준비 완료 시 콜백 */
  onReady?: () => void;
}

// =============================================================================
// 컴포넌트
// =============================================================================

export const GodotGame: React.FC<GodotGameProps> = ({
  pckPath: _pckPath,  // Reserved for GodotView
  showLoading = true,
  onError,
  onReady,
}) => {
  const isConnected = useGodotConnection();
  // Reserved for GodotView component
  const godotViewRef = useRef<View | null>(null);

  // 오프라인 보상 훅
  useOfflineReward({
    baseGoldPerHour: 100, // 기본 시간당 골드
    tickInterval: 0.1, // 100ms 틱
  });

  /**
   * Godot 메시지 핸들러 (GodotView 활성화 시 사용)
   */
  const handleGodotMessage = useCallback((rawMessage: string) => {
    try {
      const message: GodotMessage = JSON.parse(rawMessage);
      console.log('[GodotGame] Message from Godot:', message.type);
      // GodotBridge에서 리스너들에게 자동 분배됨
    } catch (error) {
      console.error('[GodotGame] Failed to parse message:', error);
    }
  }, []);

  /**
   * 게임 준비 완료 핸들러
   */
  const handleReady = useCallback(() => {
    console.log('[GodotGame] Game ready');
    onReady?.();
  }, [onReady]);

  /**
   * 에러 핸들러
   */
  const handleError = useCallback(
    (error: Error) => {
      console.error('[GodotGame] Error:', error);
      onError?.(error);
    },
    [onError]
  );

  // 핸들러 참조 유지 (GodotView 활성화 시 사용)
  void handleGodotMessage;
  void handleReady;
  void handleError;
  void godotViewRef;

  // 연결 상태 로깅
  useEffect(() => {
    console.log('[GodotGame] Connection state:', isConnected);
  }, [isConnected]);

  return (
    <View style={styles.container}>
      {/*
        실제 GodotView 컴포넌트 (라이브러리 설치 후 활성화)

        <GodotView
          ref={godotViewRef}
          style={styles.godotView}
          source={pckPath ? { uri: pckPath } : require('../../../godot/export/mobile.pck')}
          onMessage={handleGodotMessage}
          onReady={handleReady}
          onError={handleError}
        />
      */}

      {/* 임시 플레이스홀더 */}
      <View style={styles.placeholder}>
        <Text style={styles.placeholderText}>
          Godot Game View
        </Text>
        <Text style={styles.placeholderSubtext}>
          {isConnected ? 'Connected' : 'Waiting for connection...'}
        </Text>
      </View>

      {/* 로딩 인디케이터 */}
      {showLoading && !isConnected && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="large" color="#4CAF50" />
          <Text style={styles.loadingText}>Loading game...</Text>
        </View>
      )}
    </View>
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
  godotView: {
    flex: 1,
  },
  placeholder: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#2d3825',
  },
  placeholderText: {
    color: '#ffffff',
    fontSize: 24,
    fontWeight: 'bold',
  },
  placeholderSubtext: {
    color: '#888888',
    fontSize: 14,
    marginTop: 8,
  },
  loadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
  },
  loadingText: {
    color: '#ffffff',
    marginTop: 16,
    fontSize: 16,
  },
});

export default GodotGame;
