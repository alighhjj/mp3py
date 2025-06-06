document.addEventListener('DOMContentLoaded', () => {
    const audio = new Audio();
    const playPauseBtn = document.querySelector('.player-controls .fa-play');
    const backwardBtn = document.querySelector('.player-controls .fa-backward');
    const forwardBtn = document.querySelector('.player-controls .fa-forward');
    const progressBar = document.querySelector('.playback-bar .progress');
    const currentTimeSpan = document.querySelector('.playback-bar .current-time');
    const totalTimeSpan = document.querySelector('.playback-bar .total-time');
    const volumeSlider = document.querySelector('.volume-control .volume-slider');
    const progressBarContainer = document.querySelector('.playback-bar .progress-bar'); // 获取进度条容器
    const seekThumb = document.querySelector('.playback-bar .seek-thumb'); // 获取拖动圆点
    const songItems = document.querySelectorAll('.song-item');

    let currentSongIndex = 0;
    let playlist = []; // 播放列表将从DOM中获取

    // 初始化播放器
    function initPlayer() {
        // 从DOM中获取歌曲数据
        songItems.forEach(item => {
            playlist.push({
                title: item.querySelector('.song-title').textContent,
                artist: item.querySelector('.song-artist').textContent, // 获取艺术家信息
                src: item.dataset.src
            });
        });
        if (playlist.length > 0) {
            loadSong(currentSongIndex);
            updatePlaylistUI();
        }
    }

    // 加载歌曲
    function loadSong(index) {
        const song = playlist[index];
        // 先暂停当前播放，避免播放请求冲突
        audio.pause();
        // 重置播放按钮状态
        playPauseBtn.classList.remove('fa-pause');
        playPauseBtn.classList.add('fa-play');
        // 设置新的音频源
        audio.src = song.src;
        // 移除所有歌曲项的 active 类
        document.querySelectorAll('.song-item').forEach(item => item.classList.remove('active'));
        // 为当前歌曲项添加 active 类
        songItems[index].classList.add('active');
        // 更新播放器顶部的歌曲信息
        document.querySelector('.app-title').innerHTML = `<i class="fas fa-music"></i> ${song.title}`;
        // 更新 album-info 区域的歌曲标题和艺术家
        document.querySelector('.album-info h2').textContent = song.title;
        document.querySelector('.album-info p').textContent = `by ${song.artist}`;
    }

    // 播放/暂停功能
    function togglePlayPause() {
        if (audio.paused) {
            // 使用Promise处理播放请求
            audio.play().then(() => {
                playPauseBtn.classList.remove('fa-play');
                playPauseBtn.classList.add('fa-pause');
            }).catch(error => {
                console.error('播放失败:', error);
            });
        } else {
            audio.pause();
            playPauseBtn.classList.remove('fa-pause');
            playPauseBtn.classList.add('fa-play');
        }
    }

    // 上一曲
    function playPreviousSong() {
        currentSongIndex = (currentSongIndex - 1 + playlist.length) % playlist.length;
        loadSong(currentSongIndex);
        // 等待音频加载完成后再播放
        audio.addEventListener('canplaythrough', function playWhenReady() {
            audio.removeEventListener('canplaythrough', playWhenReady);
            audio.play().then(() => {
                // 播放成功后更新按钮状态
                playPauseBtn.classList.remove('fa-play');
                playPauseBtn.classList.add('fa-pause');
            }).catch(error => {
                console.error('播放上一曲失败:', error);
            });
        });
    }

    // 下一曲
    function playNextSong() {
        currentSongIndex = (currentSongIndex + 1) % playlist.length;
        loadSong(currentSongIndex);
        // 等待音频加载完成后再播放
        audio.addEventListener('canplaythrough', function playWhenReady() {
            audio.removeEventListener('canplaythrough', playWhenReady);
            audio.play().then(() => {
                // 播放成功后更新按钮状态
                playPauseBtn.classList.remove('fa-play');
                playPauseBtn.classList.add('fa-pause');
            }).catch(error => {
                console.error('播放下一曲失败:', error);
            });
        });
    }

    // 更新播放进度条和时间
    audio.addEventListener('timeupdate', () => {
        const progressPercent = (audio.currentTime / audio.duration) * 100;
        progressBar.style.width = `${progressPercent}%`;
        currentTimeSpan.textContent = formatTime(audio.currentTime);

    });

    // 歌曲加载完成时更新总时长
    audio.addEventListener('loadedmetadata', () => {
        totalTimeSpan.textContent = formatTime(audio.duration);

    });

    // 格式化时间
    function formatTime(seconds) {
        const minutes = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return `${minutes}:${secs < 10 ? '0' : ''}${secs}`;
    }

    // 调整音量
    volumeSlider.addEventListener('input', (e) => {
        audio.volume = e.target.value / 100;
    });

    // 进度条点击和拖动跳转
    let isDragging = false;

    progressBarContainer.addEventListener('mousedown', (e) => {
        isDragging = true;
        seekThumb.style.display = 'block'; // 显示圆点
        const width = progressBarContainer.clientWidth;
        const clickX = e.offsetX;
        const percent = (clickX / width) * 100;
        seekThumb.style.left = `${percent}%`; // 设置圆点位置
        updateProgressBar(e);
    });

    document.addEventListener('mousemove', (e) => {
        if (isDragging) {
            updateProgressBar(e);
            // 更新圆点位置
            const width = progressBarContainer.clientWidth;
            const clickX = e.offsetX;
            const percent = (clickX / width) * 100;
            seekThumb.style.left = `${percent}%`;
        }
    });

    document.addEventListener('mouseup', () => {
        isDragging = false;
        seekThumb.style.display = 'none'; // 隐藏圆点
    });

    function updateProgressBar(e) {
        const width = progressBarContainer.clientWidth;
        const clickX = e.offsetX;
        const duration = audio.duration;
        audio.currentTime = (clickX / width) * duration;
    }

    // 歌曲播放结束自动播放下一曲
    audio.addEventListener('ended', () => {
        playNextSong();
    });

    // 更新播放列表UI
    function updatePlaylistUI() {
        songItems.forEach((item, index) => {
            item.addEventListener('click', () => {
                currentSongIndex = index;
                loadSong(currentSongIndex);
                // 等待音频加载完成后再播放
                audio.addEventListener('canplaythrough', function playWhenReady() {
                    audio.removeEventListener('canplaythrough', playWhenReady);
                    audio.play().then(() => {
                        // 播放成功后更新按钮状态
                        playPauseBtn.classList.remove('fa-play');
                        playPauseBtn.classList.add('fa-pause');
                    }).catch(error => {
                        console.error('播放失败:', error);
                    });
                });
            });
        });
    }

    // 事件监听
    playPauseBtn.addEventListener('click', togglePlayPause);
    backwardBtn.addEventListener('click', playPreviousSong);
    forwardBtn.addEventListener('click', playNextSong);

    // 初始化播放器
    initPlayer();
});
