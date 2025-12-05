// 下载选择弹窗功能

// 创建下载选择弹窗
function createDownloadModal() {
    const modal = document.createElement('div');
    modal.id = 'downloadModal';
    modal.className = 'download-modal';
    modal.innerHTML = `
        <div class="download-modal-overlay"></div>
        <div class="download-modal-content">
            <h3>选择下载方式</h3>
            <div class="download-modal-buttons">
                <button class="download-modal-btn download-to-browser" data-action="browser">
                    <i class="fas fa-download"></i>
                    <span>直接下载</span>
                    <small>下载到浏览器所在设备</small>
                </button>
                <button class="download-modal-btn download-to-server" data-action="server">
                    <i class="fas fa-server"></i>
                    <span>下载到服务器</span>
                    <small>保存到服务器目录</small>
                </button>
            </div>
            <button class="download-modal-close">
                <i class="fas fa-times"></i>
            </button>
        </div>
    `;
    document.body.appendChild(modal);
    return modal;
}

// 显示下载选择弹窗
function showDownloadModal(song, quality) {
    let modal = document.getElementById('downloadModal');
    if (!modal) {
        modal = createDownloadModal();
    }

    // 存储当前下载信息
    modal.dataset.songData = JSON.stringify(song);
    modal.dataset.quality = quality;

    // 显示弹窗
    modal.classList.add('show');

    // 绑定事件
    const overlay = modal.querySelector('.download-modal-overlay');
    const closeBtn = modal.querySelector('.download-modal-close');
    const browserBtn = modal.querySelector('[data-action="browser"]');
    const serverBtn = modal.querySelector('[data-action="server"]');

    const closeModal = () => {
        modal.classList.remove('show');
    };

    overlay.onclick = closeModal;
    closeBtn.onclick = closeModal;

    browserBtn.onclick = async () => {
        closeModal();
        await downloadToBrowser(song, quality);
    };

    serverBtn.onclick = async () => {
        closeModal();
        await downloadToServer(song, quality);
    };
}

// 下载到浏览器
async function downloadToBrowser(song, quality) {
    try {
        showNotification("正在准备下载...");

        const audioUrl = API.getSongUrl(song, quality);
        const audioData = await API.fetchJson(audioUrl);

        if (!audioData || !audioData.url) {
            throw new Error('获取下载地址失败');
        }

        const downloadUrl = buildAudioProxyUrl(audioData.url);
        const qualityLabel = QUALITY_LEVELS.find(q => q.value === quality)?.label || quality;
        const filename = `${song.name} - ${Array.isArray(song.artist) ? song.artist.join(', ') : song.artist} [${qualityLabel}].mp3`;

        // 创建隐藏的下载链接
        const link = document.createElement('a');
        link.href = downloadUrl;
        link.download = filename;
        link.style.display = 'none';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        showNotification(`开始下载: ${song.name}`, 'success');
    } catch (error) {
        console.error('下载失败:', error);
        showNotification('下载失败，请稍后重试', 'error');
    }
}

// 下载到服务器
async function downloadToServer(song, quality) {
    try {
        showNotification("正在下载到服务器...");

        const audioUrl = API.getSongUrl(song, quality);
        const audioData = await API.fetchJson(audioUrl);

        if (!audioData || !audioData.url) {
            throw new Error('获取下载地址失败');
        }

        const qualityLabel = QUALITY_LEVELS.find(q => q.value === quality)?.label || quality;
        const filename = `${song.name} - ${Array.isArray(song.artist) ? song.artist.join(', ') : song.artist} [${qualityLabel}].mp3`;

        // 调用服务器下载 API
        const response = await fetch('/api/download-to-server', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include',
            body: JSON.stringify({
                url: audioData.url,
                filename: filename
            })
        });

        const result = await response.json();

        if (result.success) {
            showNotification(`下载成功: ${filename}`, 'success');
        } else {
            throw new Error(result.error || '下载失败');
        }
    } catch (error) {
        console.error('下载到服务器失败:', error);
        showNotification(`下载失败: ${error.message}`, 'error');
    }
}

// 导出函数供全局使用
window.showDownloadModal = showDownloadModal;
window.downloadToBrowser = downloadToBrowser;
window.downloadToServer = downloadToServer;
