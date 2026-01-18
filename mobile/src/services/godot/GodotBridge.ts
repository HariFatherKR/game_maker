/**
 * GodotBridge - Godot <-> React Native 통신 브릿지
 *
 * Godot 게임 엔진과 React Native 앱 간의
 * 양방향 통신을 담당합니다.
 */

import { NativeEventEmitter, NativeModules } from 'react-native';

// =============================================================================
// 타입 정의
// =============================================================================

/** Godot에서 오는 메시지 타입 */
export type GodotMessageType =
  | 'SAVE_GAME'
  | 'LOAD_GAME'
  | 'PURCHASE_REQUEST'
  | 'NOTIFICATION_SCHEDULE'
  | 'ANALYTICS_EVENT'
  | 'CLOUD_SAVE'
  | 'CLOUD_LOAD'
  | 'HAPTIC_FEEDBACK'
  | 'REVIEW_REQUEST'
  | 'SHARE'
  | 'AD_SHOW';

/** Native에서 Godot으로 보내는 메시지 타입 */
export type NativeMessageType =
  | 'PURCHASE_RESULT'
  | 'OFFLINE_REWARD'
  | 'PUSH_TOKEN'
  | 'CLOUD_DATA'
  | 'AD_COMPLETED'
  | 'APP_STATE_CHANGE'
  | 'DEEP_LINK';

/** 메시지 구조 */
export interface GodotMessage<T = unknown> {
  type: GodotMessageType;
  payload: T;
  timestamp: number;
}

export interface NativeMessage<T = unknown> {
  type: NativeMessageType;
  payload: T;
  timestamp: number;
}

/** 콜백 타입 */
export type MessageCallback<T = unknown> = (message: GodotMessage<T>) => void;

// =============================================================================
// 페이로드 타입 정의
// =============================================================================

export interface SaveGamePayload {
  data: Record<string, unknown>;
  slot?: number;
}

export interface PurchaseRequestPayload {
  productId: string;
  quantity?: number;
}

export interface NotificationPayload {
  title: string;
  body: string;
  delaySeconds: number;
  id?: string;
}

export interface AnalyticsPayload {
  eventName: string;
  params?: Record<string, unknown>;
}

export interface OfflineRewardPayload {
  offlineDuration: number;
  rewards: {
    gold?: number;
    gems?: number;
    growthTicks?: number;
  };
}

// =============================================================================
// GodotBridge 클래스
// =============================================================================

class GodotBridgeService {
  private eventEmitter: NativeEventEmitter | null = null;
  private listeners: Map<GodotMessageType, Set<MessageCallback>> = new Map();
  private connectionListeners: Set<(connected: boolean) => void> = new Set();
  private isConnected: boolean = false;
  private pendingMessages: NativeMessage[] = [];

  constructor() {
    this.initialize();
  }

  /**
   * 브릿지 초기화
   */
  private initialize(): void {
    try {
      if (NativeModules.GodotModule) {
        this.eventEmitter = new NativeEventEmitter(NativeModules.GodotModule);

        // Godot에서 오는 메시지 리스너
        this.eventEmitter.addListener('onGodotMessage', this.handleGodotMessage);

        // 연결 상태 리스너
        this.eventEmitter.addListener('onGodotConnected', this.handleConnected);
        this.eventEmitter.addListener('onGodotDisconnected', this.handleDisconnected);

        console.log('[GodotBridge] Initialized');
      } else {
        console.warn('[GodotBridge] GodotModule not available');
      }
    } catch (error) {
      console.error('[GodotBridge] Initialization failed:', error);
    }
  }

  /**
   * Godot 메시지 처리
   */
  private handleGodotMessage = (rawMessage: string): void => {
    try {
      const message: GodotMessage = JSON.parse(rawMessage);
      console.log('[GodotBridge] Received:', message.type);

      // 등록된 리스너들에게 전달
      const callbacks = this.listeners.get(message.type);
      if (callbacks) {
        callbacks.forEach(callback => callback(message));
      }
    } catch (error) {
      console.error('[GodotBridge] Failed to parse message:', error);
    }
  };

  /**
   * 연결됨 처리
   */
  private handleConnected = (): void => {
    console.log('[GodotBridge] Connected to Godot');
    this.isConnected = true;

    // 연결 리스너들에게 알림
    this.connectionListeners.forEach(callback => callback(true));

    // 대기 중인 메시지 전송
    this.flushPendingMessages();
  };

  /**
   * 연결 해제됨 처리
   */
  private handleDisconnected = (): void => {
    console.log('[GodotBridge] Disconnected from Godot');
    this.isConnected = false;

    // 연결 리스너들에게 알림
    this.connectionListeners.forEach(callback => callback(false));
  };

  /**
   * 대기 중인 메시지 전송
   */
  private flushPendingMessages(): void {
    while (this.pendingMessages.length > 0) {
      const message = this.pendingMessages.shift();
      if (message) {
        this.sendToGodot(message.type, message.payload);
      }
    }
  }

  // ===========================================================================
  // Public API
  // ===========================================================================

  /**
   * 메시지 리스너 등록
   */
  public on<T>(type: GodotMessageType, callback: MessageCallback<T>): () => void {
    if (!this.listeners.has(type)) {
      this.listeners.set(type, new Set());
    }

    this.listeners.get(type)!.add(callback as MessageCallback);

    // 구독 해제 함수 반환
    return () => {
      this.listeners.get(type)?.delete(callback as MessageCallback);
    };
  }

  /**
   * 메시지 리스너 해제
   */
  public off<T>(type: GodotMessageType, callback: MessageCallback<T>): void {
    this.listeners.get(type)?.delete(callback as MessageCallback);
  }

  /**
   * 연결 상태 변경 리스너 등록
   */
  public onConnectionChange(callback: (connected: boolean) => void): () => void {
    this.connectionListeners.add(callback);

    return () => {
      this.connectionListeners.delete(callback);
    };
  }

  /**
   * Godot으로 메시지 전송
   */
  public sendToGodot<T>(type: NativeMessageType, payload: T): void {
    const message: NativeMessage<T> = {
      type,
      payload,
      timestamp: Date.now(),
    };

    if (!this.isConnected) {
      console.log('[GodotBridge] Queuing message (not connected):', type);
      this.pendingMessages.push(message);
      return;
    }

    try {
      if (NativeModules.GodotModule?.sendMessage) {
        NativeModules.GodotModule.sendMessage(JSON.stringify(message));
        console.log('[GodotBridge] Sent:', type);
      } else if (typeof window !== 'undefined' && (window as any).godotMessage) {
        // 웹뷰 환경
        (window as any).godotMessage(message);
      }
    } catch (error) {
      console.error('[GodotBridge] Failed to send message:', error);
    }
  }

  /**
   * 연결 상태 확인
   */
  public getIsConnected(): boolean {
    return this.isConnected;
  }

  // ===========================================================================
  // 편의 메서드
  // ===========================================================================

  /**
   * 오프라인 보상 전송
   */
  public sendOfflineReward(reward: OfflineRewardPayload): void {
    this.sendToGodot('OFFLINE_REWARD', reward);
  }

  /**
   * 구매 결과 전송
   */
  public sendPurchaseResult(success: boolean, productId: string, error?: string): void {
    this.sendToGodot('PURCHASE_RESULT', {
      success,
      productId,
      error,
    });
  }

  /**
   * 푸시 토큰 전송
   */
  public sendPushToken(token: string): void {
    this.sendToGodot('PUSH_TOKEN', { token });
  }

  /**
   * 클라우드 데이터 전송
   */
  public sendCloudData(data: Record<string, unknown>): void {
    this.sendToGodot('CLOUD_DATA', { data });
  }

  /**
   * 앱 상태 변경 전송
   */
  public sendAppStateChange(state: 'active' | 'background' | 'inactive'): void {
    this.sendToGodot('APP_STATE_CHANGE', { state });
  }

  /**
   * 광고 완료 전송
   */
  public sendAdCompleted(adType: string, reward?: unknown): void {
    this.sendToGodot('AD_COMPLETED', { adType, reward });
  }

  /**
   * 정리
   */
  public destroy(): void {
    this.eventEmitter?.removeAllListeners('onGodotMessage');
    this.eventEmitter?.removeAllListeners('onGodotConnected');
    this.eventEmitter?.removeAllListeners('onGodotDisconnected');
    this.listeners.clear();
    console.log('[GodotBridge] Destroyed');
  }
}

// =============================================================================
// 싱글톤 인스턴스 export
// =============================================================================

export const GodotBridge = new GodotBridgeService();
export default GodotBridge;
