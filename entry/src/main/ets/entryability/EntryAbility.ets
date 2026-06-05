import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { SettingsManager } from '../common/SettingsManager';
import { CommandManager } from '../common/CommandManager';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  private hasRequestedPermissions: boolean = false; // 标记是否已请求过权限

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
    
    // 初始化设置和指令管理器
    SettingsManager.getInstance().initialize(this.context);
    CommandManager.getInstance().initialize(this.context);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');

      // 页面加载完成后请求权限
      setTimeout(() => {
        this.checkAndRequestBluetoothPermissions();
      }, 500);
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }

  /**
   * 检查并请求蓝牙权限
   */
  private async checkAndRequestBluetoothPermissions(): Promise<void> {
    if (this.hasRequestedPermissions) {
      return;
    }
    this.hasRequestedPermissions = true;
    
    try {
      // 定义需要的蓝牙权限
      const permissions: Array<Permissions> = [
        'ohos.permission.USE_BLUETOOTH',
        'ohos.permission.DISCOVER_BLUETOOTH',
        'ohos.permission.ACCESS_BLUETOOTH',
        'ohos.permission.APPROXIMATELY_LOCATION',
        'ohos.permission.LOCATION'
      ]; 

      const atManager = abilityAccessCtrl.createAtManager();
      
      // 首次申请权限
      hilog.info(DOMAIN, TAG, 'Requesting Bluetooth permissions');
      const result = await atManager.requestPermissionsFromUser(this.context, permissions);

      // 检查请求结果
      let allGranted = true;
      let needSecondRequest = true;
      
      for (let i = 0; i < result.authResults.length; i++) {
        if (result.authResults[i] !== 0) {
          allGranted = false;
          // authResults为-1且dialogShownResults为false，说明用户之前拒绝过，需要二次申请
          if (result.authResults[i] === -1 && 
              result.dialogShownResults && 
              result.dialogShownResults[i] === false) {
            needSecondRequest = true;
            hilog.warn(DOMAIN, TAG, `Permission ${permissions[i]} previously denied, will request again via settings`);
          } else {
            hilog.warn(DOMAIN, TAG, `Permission ${permissions[i]} denied by user`);
          }
        } else {
          hilog.info(DOMAIN, TAG, `Permission ${permissions[i]} granted`);
        }
      }
      
      if (allGranted) {
        hilog.info(DOMAIN, TAG, 'All Bluetooth permissions granted');
      } else if (needSecondRequest) {
        // 二次申请：通过设置界面申请权限
        hilog.info(DOMAIN, TAG, 'Attempting second permission request via settings');
        await this.requestPermissionsOnSetting(permissions);
      } else {
        hilog.warn(DOMAIN, TAG, 'Some Bluetooth permissions denied, Bluetooth features may not work properly');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to check/request Bluetooth permissions: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 二次申请权限：通过设置界面
   */
  private async requestPermissionsOnSetting(permissions: Array<Permissions>): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionOnSetting(this.context, permissions);
      hilog.info(DOMAIN, TAG, 'Second permission request initiating');
      
      hilog.info(DOMAIN, TAG, 'Second permission request result: %{public}s', JSON.stringify(result));
      
      let allGranted = true;
      for (let i = 0; i < result.length; i++) {
        if (result[i] !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          allGranted = false;
          hilog.warn(DOMAIN, TAG, `Permission ${permissions[i]} still not granted after settings request`);
        } else {
          hilog.info(DOMAIN, TAG, `Permission ${permissions[i]} granted via settings`);
        }
      }
      
      if (allGranted) {
        hilog.info(DOMAIN, TAG, 'All Bluetooth permissions granted via settings');
      } else {
        hilog.warn(DOMAIN, TAG, 'Some Bluetooth permissions still not granted');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to request permissions via settings: %{public}s', JSON.stringify(error));
    }
  }
}
