import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/radio_model.dart';
import '../controllers/radio_player_controller.dart';

class RadioHomePage extends StatefulWidget {
  const RadioHomePage({super.key});

  @override
  State<RadioHomePage> createState() => _RadioHomePageState();
}

class _RadioHomePageState extends State<RadioHomePage> with TickerProviderStateMixin {
  late final RadioPlayerController _controller;
  
  // Animations
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = RadioPlayerController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (_controller.isPlaying && !_controller.isBuffering) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.animateTo(0.0, duration: const Duration(milliseconds: 300));
      }
    }

    if (_controller.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage!,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.redAccent.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      );
      _controller.errorMessage = null;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Dynamic background based on active channel
  List<Color> _getBackgroundGradient() {
    if (_controller.currentChannel == null) {
      return [Colors.deepPurple.shade900, Colors.black, Colors.black87];
    }
    // E.g., Channel 1 gets Purple, Channel 2 gets Blue
    final idx = _controller.channels.indexOf(_controller.currentChannel!);
    if (idx % 2 == 0) {
      return [const Color(0xFF3B185F), const Color(0xFF000000), const Color(0xFF1A1A1A)];
    } else {
      return [const Color(0xFF0A2647), const Color(0xFF000000), const Color(0xFF144272)];
    }
  }
  
  Color _getPrimaryColor() {
    if (_controller.currentChannel == null) return Colors.deepPurpleAccent;
    final idx = _controller.channels.indexOf(_controller.currentChannel!);
    return idx % 2 == 0 ? Colors.purpleAccent : Colors.tealAccent;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final primaryColor = _getPrimaryColor();
        
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'BOZUK RADYO',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                fontSize: 24,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            centerTitle: true,
          ),
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getBackgroundGradient(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Premium Audio Visualizer Center Piece
                  _buildCenterVisualizer(primaryColor),
                  
                  const SizedBox(height: 40),
                  
                  // Channel List
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _controller.channels.length,
                      itemBuilder: (context, index) {
                        final channel = _controller.channels[index];
                        final isSelected = _controller.currentChannel?.url == channel.url;
                        return _buildChannelCard(channel, isSelected, primaryColor);
                      },
                    ),
                  ),
                  
                  // Mini Player replaces the huge slider alone
                  _buildMiniPlayer(primaryColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterVisualizer(Color primaryColor) {
    final bool isPlaying = _controller.isPlaying;

    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glowing ripple
              if (isPlaying && !_controller.isBuffering)
                Transform.scale(
                  scale: _scaleAnimation.value * 1.3,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: _glowAnimation.value * 0.3),
                    ),
                  ),
                ),
              // Inner glowing ripple
              if (isPlaying && !_controller.isBuffering)
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: _glowAnimation.value * 0.6),
                    ),
                  ),
                ),
              // Core Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(35),
                decoration: BoxDecoration(
                  color: isPlaying ? primaryColor.withValues(alpha: 0.15) : Colors.white10,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isPlaying ? primaryColor.withValues(alpha: 0.4) : Colors.black26,
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: isPlaying ? primaryColor.withValues(alpha: 0.5) : Colors.white24,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isPlaying ? Icons.graphic_eq_rounded : Icons.radio_rounded,
                  size: 80,
                  color: isPlaying ? primaryColor : Colors.white70,
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildChannelCard(RadioModel channel, bool isSelected, Color primaryColor) {
    return GestureDetector(
      onTap: () => _controller.playChannel(channel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? primaryColor.withValues(alpha: 0.5) : Colors.white12,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Icon indicator
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? primaryColor.withValues(alpha: 0.2) : Colors.white10,
                    ),
                    child: Icon(
                      isSelected ? Icons.radio : Icons.headphones_rounded,
                      color: isSelected ? primaryColor : Colors.white54,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          channel.name,
                          style: GoogleFonts.poppins(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 18,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                        if (isSelected)
                          Text(
                            _controller.isBuffering ? 'Bağlanıyor...' : 'Canlı Yayın',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: primaryColor.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Simple ripple indicator if playing this channel
                  if (isSelected && !_controller.isBuffering && _controller.isPlaying)
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(Icons.waves_rounded, color: primaryColor),
                    ),
                    
                  if (isSelected && _controller.isBuffering)
                     SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: primaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(Color primaryColor) {
    if (_controller.currentChannel == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withValues(alpha: 0.5),
             blurRadius: 10,
             offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Channel info + Play/Pause Button
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                         color: primaryColor.withValues(alpha: 0.2),
                         shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.music_note_rounded, color: primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _controller.currentChannel!.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _controller.isBuffering ? 'Şu an bağlanıyor...' : 'Yayında',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Play / Pause button
                    GestureDetector(
                      onTap: () => _controller.playChannel(_controller.currentChannel!),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor,
                        ),
                        child: Icon(
                          _controller.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.black87,
                          size: 28,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                // Bottom Row: Volume slider
                Row(
                  children: [
                    Icon(
                      _controller.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: primaryColor,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          overlayColor: primaryColor.withValues(alpha: 0.2),
                          trackHeight: 3.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                        ),
                        child: Slider(
                          value: _controller.volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: _controller.setVolume,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
