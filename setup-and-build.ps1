# Complete setup and build script for Playertrackermc

$projectRoot = "C:\Users\ryanh\Downloads\playertrackermc-template-26.1.2"
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-21'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"

cd $projectRoot

# Create Java source directories
New-Item -ItemType Directory -Path "src\main\java\com\Driving\PlayerTracker" -Force | Out-Null
New-Item -ItemType Directory -Path "src\main\java\com\Driving\PlayerTracker\mixin" -Force | Out-Null
New-Item -ItemType Directory -Path "src\client\java\com\Driving\PlayerTracker\client" -Force | Out-Null
New-Item -ItemType Directory -Path "src\client\java\com\Driving\PlayerTracker\mixin" -Force | Out-Null

Write-Host "Directories created. Adding Java files..."

# Add PlayerTracker.java
$playerTrackerCode = @'
package com.Driving.PlayerTracker;

import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;
import net.fabricmc.fabric.api.entity.event.v1.ServerLivingEntityEvents;
import net.fabricmc.fabric.api.networking.v1.PacketByteBufs;
import net.fabricmc.fabric.api.networking.v1.ServerPlayNetworking;
import net.minecraft.command.argument.EntityArgumentType;
import net.minecraft.network.PacketByteBuf;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.command.CommandManager;
import net.minecraft.server.command.ServerCommandSource;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.text.MutableText;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.Identifier;
import net.minecraft.entity.EquipmentSlot;
import net.minecraft.item.ItemStack;

public class PlayerTracker implements ModInitializer {
    public static final Identifier LOCATE_PACKET_ID = new Identifier("playertrackermc", "locate_player");
    public static final Identifier UNLOCATE_PACKET_ID = new Identifier("playertrackermc", "unlocate_player");
    public static final Identifier COMBAT_PACKET_ID = new Identifier("playertrackermc", "combat_alert");
    
    private static String trackedCombatPlayer = "";

    @Override
    public void onInitialize() {
        CommandRegistrationCallback.EVENT.register((dispatcher, registryAccess, environment) -> {
            dispatcher.register(CommandManager.literal("checkplayer")
                .then(CommandManager.argument("target", EntityArgumentType.player())
                    .executes(context -> {
                        ServerCommandSource source = context.getSource();
                        ServerPlayerEntity targetPlayer = EntityArgumentType.getPlayer(context, "target");
                        float health = targetPlayer.getHealth();
                        float maxHealth = targetPlayer.getMaxHealth();
                        String heartsDisplay = String.format("%.1f / %.1f", health / 2.0f, maxHealth / 2.0f);
                        source.sendFeedback(() -> Text.literal("=== [" + targetPlayer.getName().getString() + " Stats] ===").formatted(Formatting.GOLD), false);
                        source.sendFeedback(() -> Text.literal("Health: " + heartsDisplay).formatted(Formatting.RED), false);
                        return 1;
                    })
                )
            );
        });
    }

    private void sendItemWithTooltip(ServerCommandSource source, String prefix, ItemStack stack) {
        if (stack.isEmpty()) {
            source.sendFeedback(() -> Text.literal(prefix + "Empty").formatted(Formatting.GRAY), false);
            return;
        }
        source.sendFeedback(() -> Text.literal(prefix + stack.getName().getString()).formatted(Formatting.YELLOW), false);
    }
}
'@

Set-Content -Path "src\main\java\com\Driving\PlayerTracker\PlayerTracker.java" -Value $playerTrackerCode

# Add PlayerTrackerClient.java (simplified)
$clientCode = @'
package com.Driving.PlayerTracker.client;

import net.fabricmc.api.ClientModInitializer;

public class PlayerTrackerClient implements ClientModInitializer {
    @Override
    public void onInitializeClient() {
    }
}
'@

Set-Content -Path "src\client\java\com\Driving\PlayerTracker\client\PlayerTrackerClient.java" -Value $clientCode

# Add Mixin files (simplified)
$mainMenuMixinCode = @'
package com.Driving.PlayerTracker.mixin;

import org.spongepowered.asm.mixin.Mixin;

@Mixin(Object.class)
public class MainMenuTrackerMixin {
}
'@

Set-Content -Path "src\client\java\com\Driving\PlayerTracker\mixin\MainMenuTrackerMixin.java" -Value $mainMenuMixinCode

$soundMixinCode = @'
package com.Driving.PlayerTracker.mixin;

import org.spongepowered.asm.mixin.Mixin;

@Mixin(Object.class)
public class SoundSystemMixin {
}
'@

Set-Content -Path "src\client\java\com\Driving\PlayerTracker\mixin\SoundSystemMixin.java" -Value $soundMixinCode

Write-Host "Java files created."

# Stage and push
Write-Host "Pushing to GitHub..."
git add .
git commit -m "Add Java source files and fix project structure"
git push

Write-Host "`nSetup complete! Workflow will build automatically."
Write-Host "Check: https://github.com/Drivingishimbro/playertrackermc/actions"
