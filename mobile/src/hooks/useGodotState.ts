/**
 * useGodotState - Godot 상태 동기화 훅
 *
 * Godot 게임의 상태를 React 컴포넌트에서
 * 실시간으로 구독할 수 있게 해줍니다.
 */

import { useState, useEffect, useCallback } from 'react';
import { GodotBridge, GodotMessageType, MessageCallback } from '../services/godot';

/**
 * Godot 상태 구독 훅
 *
 * @param messageType 구독할 메시지 타입
 * @param initialValue 초기값
 * @returns [현재 상태, 상태 업데이트 함수]
 */
export function useGodotState<T>(
  messageType: GodotMessageType,
  initialValue: T
): [T, (value: T) => void] {
  const [state, setState] = useState<T>(initialValue);

  useEffect(() => {
    const handleMessage: MessageCallback<T> = (message) => {
      setState(message.payload as T);
    };

    const unsubscribe = GodotBridge.on<T>(messageType, handleMessage);

    return () => {
      unsubscribe();
    };
  }, [messageType]);

  const updateState = useCallback((value: T) => {
    setState(value);
  }, []);

  return [state, updateState];
}

/**
 * Godot 이벤트 구독 훅
 *
 * @param messageType 구독할 메시지 타입
 * @param callback 메시지 수신 시 호출될 콜백
 */
export function useGodotEvent<T>(
  messageType: GodotMessageType,
  callback: MessageCallback<T>
): void {
  useEffect(() => {
    const unsubscribe = GodotBridge.on<T>(messageType, callback);

    return () => {
      unsubscribe();
    };
  }, [messageType, callback]);
}

/**
 * Godot 연결 상태 훅
 *
 * @returns 연결 상태 (boolean)
 */
export function useGodotConnection(): boolean {
  const [isConnected, setIsConnected] = useState(GodotBridge.getIsConnected());

  useEffect(() => {
    // 연결 상태 변경 구독
    const unsubscribeConnected = GodotBridge.onConnectionChange((connected: boolean) => {
      setIsConnected(connected);
    });

    // 초기 상태 동기화
    setIsConnected(GodotBridge.getIsConnected());

    return () => {
      unsubscribeConnected();
    };
  }, []);

  return isConnected;
}

export default useGodotState;
