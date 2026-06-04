import { DisplayMode } from './Types';
import preferences from '@ohos.data.preferences';

/**
 * 设置管理器
 * 管理应用设置项
 */
export class SettingsManager {
  private static instance: SettingsManager;
  private static readonly PREF_NAME = 'bluetooth_remote_settings';
  
  // 设置项
  private _displayMode: DisplayMode = DisplayMode.ASCII;
  private preferences: preferences.Preferences | null = null;
  
  // 回调
  private onSettingsChange?: () => void;
  
  private constructor() {}
  
  static getInstance(): SettingsManager {
    if (!SettingsManager.instance) {
      SettingsManager.instance = new SettingsManager();
    }
    return SettingsManager.instance;
  }
  
  // Getter
  get displayMode(): DisplayMode {
    return this._displayMode;
  }
  
  set displayMode(mode: DisplayMode) {
    this._displayMode = mode;
    this.saveSettings();
    if (this.onSettingsChange) {
      this.onSettingsChange();
    }
  }
  
  setOnSettingsChange(callback: () => void) {
    this.onSettingsChange = callback;
  }
  
  /**
   * 初始化设置
   */
  async initialize(context: Context): Promise<void> {
    try {
      this.preferences = await preferences.getPreferences(context, SettingsManager.PREF_NAME);
      await this.loadSettings();
    } catch (error) {
      console.error('Settings initialization failed:', error);
    }
  }
  
  /**
   * 加载设置
   */
  private async loadSettings(): Promise<void> {
    if (!this.preferences) {
      return;
    }
    
    try {
      const modeStr = await this.preferences.get('displayMode', DisplayMode.ASCII) as string;
      this._displayMode = modeStr === DisplayMode.HEX ? DisplayMode.HEX : DisplayMode.ASCII;
    } catch (error) {
      console.error('Load settings failed:', error);
    }
  }
  
  /**
   * 保存设置
   */
  private async saveSettings(): Promise<void> {
    if (!this.preferences) {
      return;
    }
    
    try {
      await this.preferences.put('displayMode', this._displayMode);
      await this.preferences.flush();
    } catch (error) {
      console.error('Save settings failed:', error);
    }
  }
}
