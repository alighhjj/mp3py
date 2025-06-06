const express = require('express');
const path = require('path');
const fs = require('fs');
const mm = require('music-metadata');

const app = express();
const PORT = process.env.PORT || 3000;

// 设置静态文件目录
// 将 public 目录下的文件（如 CSS, JS, 图片）暴露给客户端访问
// 设置静态文件目录
// 将 public 目录下的文件（如 CSS, JS, 图片）暴露给客户端访问
app.use(express.static(path.join(__dirname, 'public')));

// 设置音乐文件目录
// 将 music 目录下的音乐文件暴露给客户端访问
app.use('/music', express.static(path.join(__dirname, 'music')));

// 设置视图引擎为 EJS
// Express 将使用 EJS 来渲染位于 views 目录下的模板文件
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// 定义根路由
// 当用户访问网站根目录时，渲染 index.ejs 模板
app.get('/', (req, res) => {
  const musicDir = path.join(__dirname, 'music');
  fs.readdir(musicDir, (err, files) => {
    if (err) {
      console.error('无法读取音乐目录:', err);
      return res.status(500).send('服务器错误');
    }
    const mp3Files = files.filter(file => file.endsWith('.mp3'));
    const songs = [];

    // 使用 Promise.all 来等待所有元数据读取完成
    Promise.all(mp3Files.map(async (file) => {
      const filePath = path.join(musicDir, file);
      try {
        const metadata = await mm.parseFile(filePath);
        // 格式化时长为 mm:ss 格式
        const formatDuration = (seconds) => {
          if (!seconds || isNaN(seconds)) return '--:--';
          const mins = Math.floor(seconds / 60);
          const secs = Math.floor(seconds % 60);
          return `${mins}:${secs.toString().padStart(2, '0')}`;
        };
        
        songs.push({
          title: metadata.common.title || file.replace('.mp3', ''),
          artist: metadata.common.artist || '未知艺术家',
          duration: formatDuration(metadata.format.duration),
          src: `/music/${encodeURIComponent(file)}`
        });
      } catch (metadataErr) {
        console.error(`无法读取 ${file} 的元数据:`, metadataErr.message);
        songs.push({
          title: file.replace('.mp3', ''),
          artist: '未知艺术家',
          duration: '--:--',
          src: `/music/${encodeURIComponent(file)}`
        });
      }
    })).then(() => {
      console.log('Songs array:', songs);
      res.render('index', { title: '音乐播放器', songs: songs });
    }).catch(err => {
      console.error('处理音乐文件时发生错误:', err);
      res.status(500).send('服务器错误');
    });
  });
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});