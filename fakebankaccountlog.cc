/*
* Random MEaningless Code to show off vim/term and tmux etup
/*

#include <iostream>
#include <string_view>

struct bank {
    int64_t accountNum;
    int32_t money;
};

struct person {
    std::string_view name;
    int32_t age;
    bank bankAccount;
};

person* create_person(std::string_view name, int32_t age, int64_t accountNum, int32_t money) {
    auto p = static_cast<person*>(std::malloc(sizeof(person)));
    p->name = name;
    p->age = age;
    p->bankAccount.accountNum = accountNum;
    p->bankAccount.money = money;
    return p;
}

void display_person(person* p) {
    std::printf("Name: %s\nAge: %d\nBank Account: %lld\nAmount: %d\n",
                p->name.data(), p->age, p->bankAccount.accountNum, p->bankAccount.money);
}

int main() {
    auto ethan = create_person("Ethan", 21, 123456789, 2100);
    display_person(ethan);

    
    std::free(ethan);

    return 0;
}
