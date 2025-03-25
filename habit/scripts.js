// 初始化 localStorage 資料結構
function initializeLocalStorage() {
    if (!localStorage.getItem('habits')) {
        localStorage.setItem('habits', JSON.stringify([]));
    }

    if (!localStorage.getItem('achievements')) {
        localStorage.setItem('achievements', JSON.stringify({
            'habit_former': false,
            'persistent': false,
            'habit_master': false
        }));
    }

    if (!localStorage.getItem('stats')) {
        localStorage.setItem('stats', JSON.stringify({
            totalCompletions: 0,
            longestStreak: 0,
            habitCount: 0,
            weeklyCompletionRate: 0
        }));
    }

    if (!localStorage.getItem('settings')) {
        localStorage.setItem('settings', JSON.stringify({
            notifications: true,
            darkMode: false,
            language: '繁體中文'
        }));
    }
}

// 獲取資料
function getHabits() {
    return JSON.parse(localStorage.getItem('habits')) || [];
}

function getHabitById(id) {
    const habits = getHabits();
    return habits.find(habit => habit.id === id);
}

function getAchievements() {
    return JSON.parse(localStorage.getItem('achievements')) || {};
}

function getStats() {
    return JSON.parse(localStorage.getItem('stats')) || {};
}

function getSettings() {
    return JSON.parse(localStorage.getItem('settings')) || {};
}

// 保存資料
function saveHabits(habits) {
    localStorage.setItem('habits', JSON.stringify(habits));
    updateStats();
    checkAchievements();
    renderDashboard();
}

function saveAchievements(achievements) {
    localStorage.setItem('achievements', JSON.stringify(achievements));
}

function saveStats(stats) {
    localStorage.setItem('stats', JSON.stringify(stats));
}

function saveSettings(settings) {
    localStorage.setItem('settings', JSON.stringify(settings));
    applySettings();
}

// 創建新習慣
function createHabit(habitData) {
    const habits = getHabits();
    
    const newHabit = {
        id: Date.now().toString(), // 使用時間戳作為唯一ID
        name: habitData.name,
        icon: habitData.icon,
        frequency: habitData.frequency,
        timeGoal: habitData.timeGoal || '',
        cue: habitData.cue || '',
        motivation: habitData.motivation || '',
        steps: habitData.steps || '',
        reward: habitData.reward || '',
        createdAt: new Date().toISOString(),
        completions: [], // 記錄所有完成日期
        currentStreak: 0, // 當前連續天數
        bestStreak: 0,    // 最佳連續天數
        completionRate: 0 // 完成率
    };
    
    habits.push(newHabit);
    saveHabits(habits);
    
    return newHabit;
}

// 更新習慣信息
function updateHabit(id, updatedData) {
    const habits = getHabits();
    const index = habits.findIndex(habit => habit.id === id);
    
    if (index !== -1) {
        habits[index] = {
            ...habits[index],
            ...updatedData
        };
        
        saveHabits(habits);
        return habits[index];
    }
    
    return null;
}

// 刪除習慣
function deleteHabit(id) {
    const habits = getHabits();
    const filteredHabits = habits.filter(habit => habit.id !== id);
    
    saveHabits(filteredHabits);
}

// 標記習慣為完成/未完成
function toggleHabitCompletion(id) {
    const habits = getHabits();
    const index = habits.findIndex(habit => habit.id === id);
    
    if (index !== -1) {
        const today = new Date().toISOString().split('T')[0]; // 只獲取日期部分 YYYY-MM-DD
        const completionIndex = habits[index].completions.indexOf(today);
        
        if (completionIndex === -1) {
            // 標記為完成
            habits[index].completions.push(today);
            updateHabitStreak(habits[index]);
        } else {
            // 標記為未完成
            habits[index].completions.splice(completionIndex, 1);
            updateHabitStreak(habits[index]);
        }
        
        saveHabits(habits);
        return habits[index];
    }
    
    return null;
}

// 更新習慣的連續天數
function updateHabitStreak(habit) {
    if (!habit.completions.length) {
        habit.currentStreak = 0;
        habit.completionRate = 0;
        return;
    }
    
    // 按日期排序
    const sortedCompletions = [...habit.completions].sort();
    const today = new Date().toISOString().split('T')[0];
    const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
    
    // 今天或昨天完成了
    const recentlyCompleted = sortedCompletions.includes(today) || sortedCompletions.includes(yesterday);
    
    // 如果最近沒有完成，重置連續天數
    if (!recentlyCompleted) {
        habit.currentStreak = 0;
    } else {
        // 計算連續天數
        let streak = 1;
        let lastDate = new Date(sortedCompletions[sortedCompletions.length - 1]);
        
        for (let i = sortedCompletions.length - 2; i >= 0; i--) {
            const currentDate = new Date(sortedCompletions[i]);
            const dayDiff = Math.floor((lastDate - currentDate) / (1000 * 60 * 60 * 24));
            
            if (dayDiff === 1) {
                streak++;
                lastDate = currentDate;
            } else if (dayDiff !== 0) { // 跳過重複的日期
                break;
            }
        }
        
        habit.currentStreak = streak;
    }
    
    // 更新最佳連續天數
    if (habit.currentStreak > habit.bestStreak) {
        habit.bestStreak = habit.currentStreak;
    }
    
    // 計算完成率 (過去30天)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const thirtyDaysAgoStr = thirtyDaysAgo.toISOString().split('T')[0];
    
    const recentCompletions = habit.completions.filter(date => date >= thirtyDaysAgoStr);
    habit.completionRate = Math.round((recentCompletions.length / 30) * 100);
}

// 更新統計數據
function updateStats() {
    const habits = getHabits();
    const stats = getStats();
    
    // 總習慣數
    stats.habitCount = habits.length;
    
    // 計算總完成次數
    stats.totalCompletions = habits.reduce((sum, habit) => sum + habit.completions.length, 0);
    
    // 最長連續天數
    stats.longestStreak = habits.reduce((max, habit) => Math.max(max, habit.bestStreak), 0);
    
    // 本週完成率
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - weekStart.getDay()); // 獲取本週第一天
    const weekStartStr = weekStart.toISOString().split('T')[0];
    
    let weeklyCompletions = 0;
    let weeklyPossible = 0;
    
    habits.forEach(habit => {
        const weekCompletions = habit.completions.filter(date => date >= weekStartStr);
        weeklyCompletions += weekCompletions.length;
        
        // 根據習慣頻率計算可能的完成次數
        let possibleDays = 0;
        const today = new Date();
        const daysPassed = Math.min(7, today.getDay() + 1); // 本週已過天數 (最多7天)
        
        switch(habit.frequency) {
            case '每天':
                possibleDays = daysPassed;
                break;
            case '工作日':
                possibleDays = Math.min(5, daysPassed);
                break;
            case '週末':
                possibleDays = Math.min(2, Math.max(0, daysPassed - 5));
                break;
            case '每週':
                possibleDays = 1;
                break;
            default:
                possibleDays = daysPassed;
        }
        
        weeklyPossible += possibleDays;
    });
    
    stats.weeklyCompletionRate = weeklyPossible === 0 ? 0 : Math.round((weeklyCompletions / weeklyPossible) * 100);
    
    saveStats(stats);
}

// 檢查並更新成就
function checkAchievements() {
    const habits = getHabits();
    const achievements = getAchievements();
    
    // 習慣養成者: 成功完成一個習慣連續7天
    achievements.habit_former = habits.some(habit => habit.bestStreak >= 7);
    
    // 堅持不懈: 完成一個習慣總計30天
    achievements.persistent = habits.some(habit => habit.completions.length >= 30);
    
    // 習慣大師: 同時保持3個習慣連續30天
    const habitsWithLongStreak = habits.filter(habit => habit.bestStreak >= 30);
    achievements.habit_master = habitsWithLongStreak.length >= 3;
    
    saveAchievements(achievements);
}

// 渲染儀表板
function renderDashboard() {
    const habits = getHabits();
    const stats = getStats();
    const habitsContainer = document.getElementById('habits-container');
    
    if (!habitsContainer) return;
    
    // 清空原有內容
    habitsContainer.innerHTML = '';
    
    if (habits.length === 0) {
        habitsContainer.innerHTML = `
            <div class="card" style="text-align: center; padding: 30px;">
                <i class="fas fa-seedling" style="font-size: 40px; color: var(--primary-light); margin-bottom: 20px;"></i>
                <h2>開始您的習慣之旅</h2>
                <p style="margin-bottom: 20px;">添加您的第一個習慣以開始追蹤</p>
                <button class="btn btn-primary" onclick="showScreen('create-habit-screen')">
                    <i class="fas fa-plus"></i> 添加習慣
                </button>
            </div>
        `;
        return;
    }
    
    // 渲染每個習慣卡片
    habits.forEach(habit => {
        const today = new Date().toISOString().split('T')[0];
        const isCompletedToday = habit.completions.includes(today);
        
        const habitCard = document.createElement('div');
        habitCard.className = 'card habit-card';
        habitCard.setAttribute('data-id', habit.id);
        habitCard.onclick = () => showHabitDetail(habit.id);
        
        habitCard.innerHTML = `
            <div class="habit-icon">
                <i class="${habit.icon}"></i>
            </div>
            <div class="habit-info">
                <div class="habit-title">${habit.name}</div>
                <div class="habit-subtitle">${habit.frequency}${habit.timeGoal ? ' ' + habit.timeGoal : ''} - ${habit.motivation || '養成好習慣'}</div>
            </div>
            <div class="habit-action" onclick="event.stopPropagation()">
                ${isCompletedToday ? 
                    `<div class="circle-progress">${habit.completionRate}%</div>` : 
                    `<button class="btn btn-outline" onclick="completeHabit('${habit.id}')">完成</button>`
                }
            </div>
        `;
        
        habitsContainer.appendChild(habitCard);
    });
    
    // 更新進度概覽
    document.querySelector('.big-circle-progress .percentage').textContent = `${stats.weeklyCompletionRate}%`;
    document.querySelectorAll('.progress-stats .stat-value')[0].textContent = stats.totalCompletions;
    document.querySelectorAll('.progress-stats .stat-value')[1].textContent = stats.longestStreak;
    document.querySelectorAll('.progress-stats .stat-value')[2].textContent = stats.habitCount;
}

// 渲染習慣詳情頁面
function renderHabitDetail(habitId) {
    const habit = getHabitById(habitId);
    
    if (!habit) return;
    
    // 更新頁面上的習慣信息
    const detailScreen = document.getElementById('habit-detail-screen');
    const habitIcon = detailScreen.querySelector('.habit-icon i');
    const habitTitle = detailScreen.querySelector('.habit-title');
    const habitSubtitle = detailScreen.querySelector('.habit-subtitle');
    const editButton = detailScreen.querySelector('.habit-action button');
    
    habitIcon.className = habit.icon;
    habitTitle.textContent = habit.name;
    habitSubtitle.textContent = `${habit.frequency}${habit.timeGoal ? ' ' + habit.timeGoal : ''} - ${habit.motivation || '養成好習慣'}`;
    editButton.onclick = () => editHabit(habitId);
    
    // 更新進度圖表
    detailScreen.querySelector('.big-circle-progress .percentage').textContent = `${habit.completionRate}%`;
    detailScreen.querySelectorAll('.progress-stats .stat-value')[0].textContent = habit.completions.length;
    detailScreen.querySelectorAll('.progress-stats .stat-value')[1].textContent = habit.currentStreak;
    detailScreen.querySelectorAll('.progress-stats .stat-value')[2].textContent = 
        Math.ceil((new Date() - new Date(habit.createdAt)) / (1000 * 60 * 60 * 24));
    
    // 渲染習慣鏈信息
    const cueElement = detailScreen.querySelector('.form-group:nth-of-type(1) div:not(.form-label)');
    const motivationElement = detailScreen.querySelector('.form-group:nth-of-type(2) div:not(.form-label)');
    const stepsElement = detailScreen.querySelector('.form-group:nth-of-type(3) div:not(.form-label)');
    const rewardElement = detailScreen.querySelector('.form-group:nth-of-type(4) div:not(.form-label)');
    
    cueElement.textContent = habit.cue || '尚未設定';
    motivationElement.textContent = habit.motivation || '尚未設定';
    stepsElement.innerHTML = habit.steps ? habit.steps.replace(/\n/g, '<br>') : '尚未設定';
    rewardElement.textContent = habit.reward || '尚未設定';
    
    // 渲染日曆
    renderCalendar(habit);
    
    // 保存當前查看的習慣ID
    currentHabitId = habitId;
}

// 渲染日曆
function renderCalendar(habit) {
    const calendarElement = document.querySelector('#habit-detail-screen .calendar');
    
    if (!calendarElement || !habit) return;
    
    // 清空除了星期標題外的內容
    const weekdayLabels = calendarElement.querySelectorAll('.calendar-day:nth-child(-n+7)');
    calendarElement.innerHTML = '';
    
    // 重新添加星期標題
    weekdayLabels.forEach(label => {
        calendarElement.appendChild(label.cloneNode(true));
    });
    
    // 獲取當前月份的第一天和最後一天
    const now = new Date();
    const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    
    // 獲取當前月份第一天是星期幾 (0-6)
    const firstDayOfWeek = firstDay.getDay();
    
    // 為第一天之前的日期添加空白
    for (let i = 0; i < (firstDayOfWeek === 0 ? 6 : firstDayOfWeek - 1); i++) {
        const emptyDay = document.createElement('div');
        emptyDay.className = 'calendar-day';
        calendarElement.appendChild(emptyDay);
    }
    
    // 為當前月份的每一天創建日曆項
    for (let day = 1; day <= lastDay.getDate(); day++) {
        const date = new Date(now.getFullYear(), now.getMonth(), day);
        const dateStr = date.toISOString().split('T')[0];
        const isCompleted = habit.completions.includes(dateStr);
        const isToday = day === now.getDate();
        
        const dayElement = document.createElement('div');
        dayElement.className = 'calendar-day';
        dayElement.textContent = day;
        
        if (isToday) {
            dayElement.classList.add('today');
        }
        
        if (date <= now) {  // 只對過去和今天的日期設置完成狀態
            if (isCompleted) {
                dayElement.classList.add('completed');
            } else {
                dayElement.classList.add('missed');
            }
        }
        
        calendarElement.appendChild(dayElement);
    }
}

// 渲染統計分析頁面
function renderStats() {
    const habits = getHabits();
    const stats = getStats();
    const statsScreen = document.getElementById('stats-screen');
    
    if (!statsScreen) return;
    
    // 更新總體統計
    statsScreen.querySelector('.big-circle-progress .percentage').textContent = `${stats.weeklyCompletionRate}%`;
    statsScreen.querySelectorAll('.progress-stats .stat-value')[0].textContent = stats.totalCompletions;
    statsScreen.querySelectorAll('.progress-stats .stat-value')[1].textContent = stats.longestStreak;
    statsScreen.querySelectorAll('.progress-stats .stat-value')[2].textContent = 
        habits.reduce((sum, habit) => sum + habit.completions.length, 0);
    
    // 渲染每個習慣的完成情況
    const habitsContainer = statsScreen.querySelector('.header + .card').nextElementSibling;
    let habitsHtml = '';
    
    habits.sort((a, b) => b.completionRate - a.completionRate).forEach(habit => {
        habitsHtml += `
            <div class="card habit-card" onclick="showHabitDetail('${habit.id}')">
                <div class="habit-icon">
                    <i class="${habit.icon}"></i>
                </div>
                <div class="habit-info">
                    <div class="habit-title">${habit.name}</div>
                    <div class="habit-subtitle">${habit.completionRate}% 完成率</div>
                </div>
                <div class="habit-action">
                    <div class="circle-progress">${habit.completionRate}%</div>
                </div>
            </div>
        `;
    });
    
    // 找到 "習慣完成情況" 標題後的容器
    const habitsSection = statsScreen.querySelector('h1:contains("習慣完成情況")').parentElement.nextElementSibling;
    habitsSection.innerHTML = habitsHtml;
    
    // 更新洞察
    renderInsights();
}

// 渲染洞察
function renderInsights() {
    const habits = getHabits();
    const statsScreen = document.getElementById('stats-screen');
    
    if (!statsScreen || habits.length === 0) return;
    
    // 獲取完成率最高和最低的習慣
    const bestHabit = habits.reduce((best, habit) => 
        habit.completionRate > best.completionRate ? habit : best, habits[0]);
    
    const worstHabit = habits.reduce((worst, habit) => 
        habit.completionRate < worst.completionRate ? habit : worst, habits[0]);
    
    // 找到洞察部分
    const insightCard = statsScreen.querySelector('h1:contains("洞察")').parentElement.nextElementSibling;
    
    // 更新洞察信息
    const insightElements = insightCard.querySelectorAll('.form-group div:not(.form-label)');
    
    // 最佳表現時間 (這僅是示例，實際可能需要更詳細的時間分析)
    insightElements[0].textContent = '早上 6:00 - 8:00';
    
    // 最容易堅持的習慣
    insightElements[1].textContent = `${bestHabit.name} (${bestHabit.completionRate}% 完成率)`;
    
    // 需要加強的習慣
    insightElements[2].textContent = `${worstHabit.name} (${worstHabit.completionRate}% 完成率)`;
    
    // 習慣建議
    insightElements[3].textContent = '考慮將習慣與現有日常活動連接，形成習慣鏈。嘗試"不要破壞連續"策略來保持動力。';
}

// 渲染成就頁面
function renderAchievements() {
    const achievements = getAchievements();
    const achievementsScreen = document.getElementById('achievements-screen');
    
    if (!achievementsScreen) return;
    
    // 更新成就狀態
    const achievementCards = achievementsScreen.querySelectorAll('.achievement-card:nth-child(-n+3)');
    
    // 習慣養成者
    if (achievements.habit_former) {
        achievementCards[0].style.opacity = '1';
    } else {
        achievementCards[0].style.opacity = '0.5';
    }
    
    // 堅持不懈
    if (achievements.persistent) {
        achievementCards[1].style.opacity = '1';
    } else {
        achievementCards[1].style.opacity = '0.5';
    }
    
    // 習慣大師
    if (achievements.habit_master) {
        achievementCards[2].style.opacity = '1';
    } else {
        achievementCards[2].style.opacity = '0.5';
    }
}

// 渲染設置頁面
function renderSettings() {
    const settings = getSettings();
    const settingsScreen = document.getElementById('settings-screen');
    
    if (!settingsScreen) return;
    
    // 更新設置狀態
    const notificationToggle = settingsScreen.querySelector('.settings-item:nth-child(1) input');
    const darkModeToggle = settingsScreen.querySelector('.settings-item:nth-child(2) input');
    const languageText = settingsScreen.querySelector('.settings-item:nth-child(4) span:last-child');
    
    notificationToggle.checked = settings.notifications;
    darkModeToggle.checked = settings.darkMode;
    languageText.textContent = settings.language;
}

// 應用設置
function applySettings() {
    const settings = getSettings();
    
    // 應用深色模式
    if (settings.darkMode) {
        document.body.classList.add('dark-mode');
    } else {
        document.body.classList.remove('dark-mode');
    }
}

// 設置切換處理
function toggleSetting(settingName) {
    const settings = getSettings();
    settings[settingName] = !settings[settingName];
    saveSettings(settings);
    renderSettings();
}

// 完成習慣
function completeHabit(id) {
    toggleHabitCompletion(id);
    
    // 更新UI
    const habitCard = document.querySelector(`.habit-card[data-id="${id}"]`);
    if (habitCard) {
        const habit = getHabitById(id);
        const habitAction = habitCard.querySelector('.habit-action');
        
        habitAction.innerHTML = `<div class="circle-progress">${habit.completionRate}%</div>`;
    }
    
    renderDashboard();
}

// 顯示習慣詳情
function showHabitDetail(habitId) {
    renderHabitDetail(habitId);
    showScreen('habit-detail-screen');
}

// 編輯習慣
function editHabit(habitId) {
    const habit = getHabitById(habitId);
    if (!habit) return;
    
    // 填充表單數據
    const form = document.getElementById('create-habit-screen');
    form.querySelector('h1').textContent = '編輯習慣';
    form.querySelector('button.full-width-btn').textContent = '更新習慣';
    form.querySelector('button.full-width-btn').onclick = () => updateHabitFromForm(habitId);
    
    form.querySelector('input[placeholder="例如：晨跑 30 分鐘"]').value = habit.name;
    form.querySelector('select').value = habit.frequency;
    form.querySelector('input[type="time"]').value = habit.timeGoal;
    form.querySelector('input[placeholder="例如：起床後，放好跑鞋"]').value = habit.cue || '';
    form.querySelector('input[placeholder="例如：提高精力，保持健康"]').value = habit.motivation || '';
    form.querySelector('textarea').value = habit.steps || '';
    form.querySelector('input[placeholder="例如：每週達標可享受一次電影夜"]').value = habit.reward || '';
    
    // 選中正確的圖標
    form.querySelectorAll('.icon-item').forEach(item => {
        item.classList.remove('selected');
        if (item.querySelector('i').className === habit.icon) {
            item.classList.add('selected');
        }
    });
    
    // 添加刪除按鈕
    if (!form.querySelector('.delete-btn')) {
        const deleteBtn = document.createElement('button');
        deleteBtn.className = 'btn btn-outline full-width-btn';
        deleteBtn.style.marginTop = '10px';
        deleteBtn.style.color = 'var(--danger)';
        deleteBtn.style.borderColor = 'var(--danger)';
        deleteBtn.textContent = '刪除習慣';
        deleteBtn.onclick = () => deleteHabitWithConfirm(habitId);
        
        form.querySelector('button.full-width-btn').parentNode.appendChild(deleteBtn);
    } else {
        form.querySelector('.delete-btn').onclick = () => deleteHabitWithConfirm(habitId);
    }
    
    showScreen('create-habit-screen');
}

// 從表單創建習慣
function createHabitFromForm() {
    const form = document.getElementById('create-habit-screen');
    
    const name = form.querySelector('input[placeholder="例如：晨跑 30 分鐘"]').value;
    if (!name) {
        alert('請輸入習慣名稱');
        return;
    }
    
    const iconItem = form.querySelector('.icon-item.selected');
    if (!iconItem) {
        alert('請選擇一個圖標');
        return;
    }
    
    const habitData = {
        name: name,
        icon: iconItem.querySelector('i').className,
        frequency: form.querySelector('select').value,
        timeGoal: form.querySelector('input[type="time"]').value,
        cue: form.querySelector('input[placeholder="例如：起床後，放好跑鞋"]').value,
        motivation: form.querySelector('input[placeholder="例如：提高精力，保持健康"]').value,
        steps: form.querySelector('textarea').value,
        reward: form.querySelector('input[placeholder="例如：每週達標可享受一次電影夜"]').value
    };
    
    createHabit(habitData);
    
    // 重置表單
    form.reset();
    form.querySelectorAll('.icon-item').forEach(item => item.classList.remove('selected'));
    form.querySelector('.icon-item:first-child').classList.add('selected');
    
    showScreen('dashboard-screen');
}

// 從表單更新習慣
function updateHabitFromForm(habitId) {
    const form = document.getElementById('create-habit-screen');
    
    const name = form.querySelector('input[placeholder="例如：晨跑 30 分鐘"]').value;
    if (!name) {
        alert('請輸入習慣名稱');
        return;
    }
    
    const iconItem = form.querySelector('.icon-item.selected');
    if (!iconItem) {
        alert('請選擇一個圖標');
        return;
    }
    
    const updatedData = {
        name: name,
        icon: iconItem.querySelector('i').className,
        frequency: form.querySelector('select').value,
        timeGoal: form.querySelector('input[type="time"]').value,
        cue: form.querySelector('input[placeholder="例如：起床後，放好跑鞋"]').value,
        motivation: form.querySelector('input[placeholder="例如：提高精力，保持健康"]').value,
        steps: form.querySelector('textarea').value,
        reward: form.querySelector('input[placeholder="例如：每週達標可享受一次電影夜"]').value
    };
    
    updateHabit(habitId, updatedData);
    
    // 重置表單為創建模式
    form.querySelector('h1').textContent = '創建新習慣';
    form.querySelector('button.full-width-btn').textContent = '創建習慣';
    form.querySelector('button.full-width-btn').onclick = createHabitFromForm;
    
    // 刪除刪除按鈕
    const deleteBtn = form.querySelector('.delete-btn');
    if (deleteBtn) {
        deleteBtn.parentNode.removeChild(deleteBtn);
    }
    
    // 重置表單
    form.reset();
    form.querySelectorAll('.icon-item').forEach(item => item.classList.remove('selected'));
    form.querySelector('.icon-item:first-child').classList.add('selected');
    
    showScreen('dashboard-screen');
}

// 確認刪除習慣
function deleteHabitWithConfirm(habitId) {
    if (confirm('確定要刪除這個習慣嗎？所有相關數據將被清除。')) {
        deleteHabit(habitId);
        
        // 重置表單為創建模式
        const form = document.getElementById('create-habit-screen');
        form.querySelector('h1').textContent = '創建新習慣';
        form.querySelector('button.full-width-btn').textContent = '創建習慣';
        form.querySelector('button.full-width-btn').onclick = createHabitFromForm;
        
        // 刪除刪除按鈕
        const deleteBtn = form.querySelector('.delete-btn');
        if (deleteBtn) {
            deleteBtn.parentNode.removeChild(deleteBtn);
        }
        
        // 重置表單
        form.reset();
        form.querySelectorAll('.icon-item').forEach(item => item.classList.remove('selected'));
        form.querySelector('.icon-item:first-child').classList.add('selected');
        
        showScreen('dashboard-screen');
    }
}

// 初始化應用
function initApp() {
    initializeLocalStorage();
    applySettings();
    setupEventListeners();
    renderDashboard();
}

// 設置事件監聽器
function setupEventListeners() {
    // 圖標選擇
    document.querySelectorAll('.icon-item').forEach(item => {
        item.addEventListener('click', function() {
            document.querySelectorAll('.icon-item').forEach(i => i.classList.remove('selected'));
            this.classList.add('selected');
        });
    });
    
    // 設置切換
    const notificationToggle = document.querySelector('.settings-item:nth-child(1) input');
    const darkModeToggle = document.querySelector('.settings-item:nth-child(2) input');
    
    if (notificationToggle) {
        notificationToggle.addEventListener('change', function() {
            toggleSetting('notifications');
        });
    }
    
    if (darkModeToggle) {
        darkModeToggle.addEventListener('change', function() {
            toggleSetting('darkMode');
        });
    }
    
    // 替換習慣創建按鈕的點擊事件
    const createHabitButton = document.querySelector('#create-habit-screen .full-width-btn');
    if (createHabitButton) {
        createHabitButton.onclick = createHabitFromForm;
    }
    
    // 替換標籤切換功能
    document.querySelectorAll('.tab-container .tab').forEach(tab => {
        tab.addEventListener('click', function() {
            const tabContainer = this.parentElement;
            tabContainer.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            this.classList.add('active');
        });
    });
}

// 當DOM加載完成後初始化應用
document.addEventListener('DOMContentLoaded', initApp);

// 全局變量
let currentHabitId = null; 