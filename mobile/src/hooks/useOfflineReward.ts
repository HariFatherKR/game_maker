/**
 * useOfflineReward - 오프라인 보상 계산 훅
 *
 * 앱이 백그라운드에 있던 시간 동안의
 * 보상을 계산하고 Godot에 전달합니다.
 */

import { useEffect, useRef, useCallback } from 'react';
import { AppState, AppStateStatus } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { GodotBridge, OfflineRewardPayload } from '../services/godot';

// =============================================================================
// 상수
// =============================================================================

const LAST_ACTIVE_KEY = '@idlefarm:lastActiveTime';
const MAX_OFFLINE_HOURS = 24;
const OFFLINE_EFFICIENCY = 0.5;

// =============================================================================
// 훅
// =============================================================================

interface UseOfflineRewardOptions {
  /** 시간당 기본 골드 생산량 */
  baseGoldPerHour: number;
  /** 성장 틱당 시간 (초) */
  tickInterval: number;
}

interface UseOfflineRewardReturn {
  /** 오프라인 보상 수동 계산 */
  calculateOfflineReward: () => Promise<OfflineRewardPayload | null>;
}

export function useOfflineReward(
  options: UseOfflineRewardOptions
): UseOfflineRewardReturn {
  const { baseGoldPerHour, tickInterval } = options;
  const appState = useRef<AppStateStatus>(AppState.currentState);

  /**
   * 마지막 활성 시간 저장
   */
  const saveLastActiveTime = useCallback(async (): Promise<void> => {
    try {
      await AsyncStorage.setItem(LAST_ACTIVE_KEY, Date.now().toString());
    } catch (error) {
      console.error('[OfflineReward] Failed to save last active time:', error);
    }
  }, []);

  /**
   * 마지막 활성 시간 가져오기
   */
  const getLastActiveTime = useCallback(async (): Promise<number | null> => {
    try {
      const value = await AsyncStorage.getItem(LAST_ACTIVE_KEY);
      return value ? parseInt(value, 10) : null;
    } catch (error) {
      console.error('[OfflineReward] Failed to get last active time:', error);
      return null;
    }
  }, []);

  /**
   * 오프라인 보상 계산
   */
  const calculateOfflineReward = useCallback(async (): Promise<OfflineRewardPayload | null> => {
    const lastActiveTime = await getLastActiveTime();

    if (!lastActiveTime) {
      console.log('[OfflineReward] No previous session found');
      return null;
    }

    const currentTime = Date.now();
    const offlineDurationMs = currentTime - lastActiveTime;
    const offlineDurationSec = Math.floor(offlineDurationMs / 1000);

    // 1분 미만은 무시
    if (offlineDurationSec < 60) {
      console.log('[OfflineReward] Duration too short:', offlineDurationSec, 's');
      return null;
    }

    // 최대 오프라인 시간 제한
    const maxOfflineSec = MAX_OFFLINE_HOURS * 3600;
    const effectiveDuration = Math.min(offlineDurationSec, maxOfflineSec);

    // 보상 계산
    const offlineHours = effectiveDuration / 3600;
    const gold = Math.floor(baseGoldPerHour * offlineHours * OFFLINE_EFFICIENCY);
    const growthTicks = Math.floor(effectiveDuration / tickInterval);

    const reward: OfflineRewardPayload = {
      offlineDuration: effectiveDuration,
      rewards: {
        gold: gold > 0 ? gold : undefined,
        growthTicks: growthTicks > 0 ? growthTicks : undefined,
      },
    };

    console.log('[OfflineReward] Calculated:', {
      duration: `${Math.round(offlineHours * 10) / 10}h`,
      gold,
      growthTicks,
    });

    // Godot에 전송
    GodotBridge.sendOfflineReward(reward);

    return reward;
  }, [baseGoldPerHour, tickInterval, getLastActiveTime]);

  /**
   * 앱 상태 변화 처리
   */
  const handleAppStateChange = useCallback(
    async (nextAppState: AppStateStatus): Promise<void> => {
      console.log('[OfflineReward] App state:', appState.current, '->', nextAppState);

      if (
        appState.current.match(/inactive|background/) &&
        nextAppState === 'active'
      ) {
        // 앱이 포그라운드로 돌아옴
        await calculateOfflineReward();
        GodotBridge.sendAppStateChange('active');
      } else if (nextAppState === 'background') {
        // 앱이 백그라운드로 감
        await saveLastActiveTime();
        GodotBridge.sendAppStateChange('background');
      } else if (nextAppState === 'inactive') {
        GodotBridge.sendAppStateChange('inactive');
      }

      appState.current = nextAppState;
    },
    [calculateOfflineReward, saveLastActiveTime]
  );

  // 앱 상태 변화 리스너
  useEffect(() => {
    const subscription = AppState.addEventListener('change', handleAppStateChange);

    // 초기 활성 시간 저장
    saveLastActiveTime();

    return () => {
      subscription.remove();
    };
  }, [handleAppStateChange, saveLastActiveTime]);

  return {
    calculateOfflineReward,
  };
}

export default useOfflineReward;
